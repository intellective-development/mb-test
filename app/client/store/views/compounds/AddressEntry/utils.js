// @flow

import uuid from 'uuid';
import _ from 'lodash';
import type { Address } from 'store/business/address';

// This is a collection of pure functions, essentially abstracted out of the address entry module
// The goal is to have each of these have simple, single responsibility

type SubstringMatch = {length: number, offset: number};
type GoogleAddressTerm = {offset: number, value: string};

// NOTE this is a the type of objects returned from google.maps.places.AutocompleteService
// an is NOT the same as the GooglePlaceAddressComponent type defined below, which defines
// the structure of objects returned from google.maps.places.PlacesService
export type GoogleAddress = {
  description: string,
  id: string,
  matched_substrings: Array<SubstringMatch>,
  place_id: string,
  reference: string,
  structured_formatting: Object, // has main text and substring matches, same for secondary text
  terms: Array<GoogleAddressTerm>,
  types: Array<string> // more of an enum along the lines of 'street_address' | 'geocode' | ...
};

// TODO: should just use legacy_store address models displayShortAddress function
export const addressToString = (address?: Address | GoogleAddress): string => {
  if (!address) return '';
  if (address.description) return address.description; // if google result just return formatted string
  const {address1, address2, city, state, zip_code} = address;
  if (!address1 || !city || !state || !zip_code) return ''; // empty string if not all components present
  let main_text = address1;
  if (address2) main_text = `${main_text}, ${address2}`; // e.g. {mt: '560 Broadway, apt 2', st: 'New York NY 10002'}
  return `${main_text}, ${city} ${state} ${zip_code}`; // e.g. 560 Broadway, New York NY 10002
};

// TODO: write generalized regex special char stripping function
export const matchChunksInString = (full_string: string, chunks: Array<string>) => {
  let test_string = full_string;
  let acc_offset = 0;
  return chunks.filter(c => c.length > 0).reduce((acc, chunk) => { // remove empty strings
    const maybe_match = test_string.match(new RegExp(chunk, 'i'));
    if (!maybe_match) return acc;
    const offset = maybe_match.index;
    const length = maybe_match[0].length;
    const match = {offset: acc_offset + offset, length};
    test_string = test_string.slice(offset + length);
    acc_offset = acc_offset + offset + length;
    return [...acc, match];
  }, []);
};

export const addressToOptionTextProps = ({address1, address2, city, state, zip_code}: Address, input_string: string) => {
  if (!address1 || !city || !state || !zip_code) return ''; // empty string if not all components present
  let main_text = address1;
  if (address2) main_text = `${main_text}, ${address2}`; // e.g. {mt: '560 Broadway, apt 2', st: 'New York NY 10002'}
  const secondary_text = `${city} ${state} ${zip_code}`;
  const input_chunks = input_string ? input_string.split(' ') : [];
  return {
    main_text,
    secondary_text,
    main_text_matches: matchChunksInString(`${main_text},`, input_chunks),
    secondary_text_matches: matchChunksInString(secondary_text, input_chunks)
  };
};

// TODO: remove this in favor of Server deduping?
// just sticking the address1 and zip together so that both are being taken into account
export const uniqAddresses = (addresses: Array<Address>) => (
  _.uniqBy(addresses, (addr) => `${addr.address1}_${addr.zip_code}`)
);

// This is a collection of pure functions, essentially abstracted out of the address entry module
// The goal is to have each of these have simple, single responsibility

const component_names: Array<string> = [
  'street_number',
  'premise',
  'route',
  'sublocality',
  'locality',
  'administrative_area_level_1',
  'postal_code'
];

// type of the object that appears within the address_components array in a google.maps.places.PlacesService response
type GooglePlacesAddressComponent = {long_name: string, short_name: string, types: Array<string>};

export const getStoreableAddress = (response, addresses) => {
  const address_components = response && getAddressComponents(response.address_components);
  const formattedAddress = formatAddressForAPI(address_components, response.geometry);
  return findStoreableAddress(formattedAddress, addresses);
};

export const findStoreableAddress = (formattedAddress, addresses) => {
  const savedAddresses = _.filter(_.values(addresses), ({ id }) => !!id);
  const foundAddresses = _.filter(savedAddresses, _.omit(formattedAddress, ['local_id', 'latitude', 'longitude']));
  // sort those that have id up (descending), pick first, if not fallback to creating new
  return _.head(_.orderBy(foundAddresses, ['id'], ['desc'])) || {local_id: uuid(), ...formattedAddress};
};

// convert googles format to object keyed by the types we want
export const getAddressComponents = (address_components: Array<GooglePlacesAddressComponent>): GoogleAddressObject => {
  const address_obj = {};

  // create an object from the array (based on the type subarray)
  _.forEach(component_names, component_name => {
    address_obj[component_name] = _.find(address_components, component => (
      _.includes(component.types, component_name)
    ));
  });

  address_obj.street_number = address_obj.street_number || address_obj.premise;
  address_obj.city = address_obj.sublocality || address_obj.locality;

  return address_obj;
};

// our object constructed from the parsed google.maps.places.PlacesService result
type GoogleAddressObject = {
  street_number?: GooglePlacesAddressComponent,
  premise?: GooglePlacesAddressComponent,
  route?: GooglePlacesAddressComponent,
  sublocality?: GooglePlacesAddressComponent,
  locality?: GooglePlacesAddressComponent,
  administrative_area_level_1?: GooglePlacesAddressComponent,
  postal_code?: GooglePlacesAddressComponent,
  city?: GooglePlacesAddressComponent
}
type GooglePlacesGeometry = {
  location: {lat: () => string, lng: () => string},
  viewport?: {
    northeast?: {lat: () => string, lng: () => string},
    southwest?: {lat: () => string, lng: () => string}
  }
}

// map to false if no street #
export const validateComponents = (address: GoogleAddressObject) => (address.street_number ? address : false);

export const formatAddressForAPI = (address: GoogleAddressObject, geometry: GooglePlacesGeometry) => {
  const street_number = formatAddressComponent(address.street_number);
  const road = formatAddressComponent(address.route);
  const city = formatAddressComponent(address.city);
  const state = formatAddressComponent(address.administrative_area_level_1, 'short_name');
  const zip_code = formatAddressComponent(address.postal_code);

  // TODO:  Test state formatter
  return {
    address1: `${street_number} ${road}`,
    city: city,
    state: state,
    zip_code: zip_code,
    latitude: geometry.location.lat(),
    longitude: geometry.location.lng()
  };
};

export const formatAddressComponent = (component?: GooglePlacesAddressComponent, length?: string = 'long_name') => (
  component ? component[length] : ''
);

// This creates a memoized function that takes a string1 and string2 and returns true
// if string2's characters appear in order within string1 with 1 char of fuzziness at the end
export const makeFuzzyMatcher = () => {
  const matcherCache = _.memoize(str => ( // interpolate every character with '?' (0 or more matcher)
    new RegExp(`^${str.replace(/./gi, x => (
      /[-[\]/{}()*+?.\\^$|]/i.test(x) ? `\\${x}?` : `${x}?` // escape special characters
    ))}.{1}$`, 'i') // .{1} gives one char of terminal fuzziness, 'i' is case insensitive
  )); // e.g. input '45 Bond' => output new RegExp('^4?5? ?B?o?n?d?.{1}$', 'i')
  return (string1: string, string2: string) => matcherCache(string1).test(string2);
};

export const nonCurrentAddresses = (addresses?: Array<Address>, current_address?: Address): Array<Address> => (
  addresses ? addresses.filter(a => a.local_id !== _.get(current_address, 'local_id')) : []
);
