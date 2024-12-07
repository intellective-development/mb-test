// @flow

import address_factory from 'store/business/address/__tests__/address.factory';
import {
  addressToString,
  matchChunksInString,
  addressToOptionTextProps,
  uniqAddresses,
  getAddressComponents,
  validateComponents,
  formatAddressForAPI,
  formatAddressComponent,
  makeFuzzyMatcher,
  nonCurrentAddresses
} from '../utils';

const address1 = '123 Fake Street';
const address2 = '5th floor';
const city = 'New York';
const state = 'NY';
const zip_code = '10001';

describe('addressToString', () => {
  it('returns string containing address1, city, state, zip_code if address2 not present', () => {
    const address_without = address_factory.build({address1, address2: '', city, state, zip_code});
    expect(addressToString(address_without)).toEqual('123 Fake Street, New York NY 10001');
  });
  it('returns string containing address1, address2, city, state, zip_code if address2 is present', () => {
    const address_with = address_factory.build({address1, address2, city, state, zip_code});
    expect(addressToString(address_with)).toEqual('123 Fake Street, 5th floor, New York NY 10001');
  });
  it('returns description string if google address', () => {
    const google_address = {description: '45 Bond Street, New York NY 10001'}; // omitting other google_address attributes for ease
    expect(addressToString(google_address)).toEqual('45 Bond Street, New York NY 10001');
  });
});

describe('matchChunksInString', () => {
  const full_string = 'This string has the word target in it';
  const chunks = ['target', ''];
  it('returns array of match objects with length and offset of the chunk within the string, and ignore empty strings', () => {
    expect(matchChunksInString(full_string, chunks)).toEqual([{offset: 25, length: 6}]);
  });
});

describe('addressToOptionTextProps', () => {
  const address = address_factory.build({address1, address2, city, state, zip_code});
  it('returns main and secondary text along with their matches from the input string', () => {
    expect(addressToOptionTextProps(address, '1')).toEqual({
      main_text: '123 Fake Street, 5th floor',
      secondary_text: 'New York NY 10001',
      main_text_matches: [{offset: 0, length: 1}],
      secondary_text_matches: [{offset: 12, length: 1}] // only catch first 1 in zip
    });
  });
});

describe('uniqAddresses', () => {
  const first_address = address_factory.build({address1, zip_code});
  const first_address_copy = address_factory.build({address1, zip_code});
  const second_address = address_factory.build();
  it('returns list of addresses without duplicates address1 zip_code combinations', () => {
    expect(uniqAddresses([first_address, first_address_copy, second_address])).toEqual([first_address, second_address]);
  });
});

describe('getAddressComponents', () => {
  const street_number = {long_name: '45 Bond', short_name: '45 Bond', types: ['street_number']};
  const sublocality = {long_name: 'New York', short_name: 'New York', types: ['sublocality']};
  const premise = {long_name: '12 Monitor', short_name: '12 Monitor', types: ['premise']};
  const locality = {long_name: 'Brooklyn', short_name: 'Brooklyn', types: ['locality']};

  it('returns an object with street_number from street_number and city from sublocality', () => {
    expect(getAddressComponents([street_number, sublocality])).toEqual(expect.objectContaining({street_number, city: sublocality}));
  });

  it('returns an object with street_number from premise and city from locality', () => {
    expect(getAddressComponents([premise, locality])).toEqual(expect.objectContaining({street_number: premise, city: locality}));
  });

  it('returns an object with attributes for whitelisted address_component types', () => {
    const non_whitelisted_type = {long_name: 'Area 51', short_name: 'Area 51', types: ['alien_zone']};
    const whitelisted_type = {long_name: 'road', short_name: 'road', types: ['route']};
    expect(getAddressComponents([whitelisted_type, non_whitelisted_type])).toEqual(expect.objectContaining({route: whitelisted_type}));
  });
});

describe('validateComponents', () => {
  it('returns address object if street number is an attribute', () => {
    const google_address_object_with = {street_number: '45 Bond', city: 'New York'};
    expect(validateComponents(google_address_object_with)).toEqual(google_address_object_with);
  });
  it('returns false if street number is not an attribute', () => {
    const google_address_object_without = {city: 'New York'};
    expect(validateComponents(google_address_object_without)).toEqual(false);
  });
});

describe('formatAddressForAPI', () => {
  it('returns address object with string values', () => {
    const street_number = {short_name: '45 Bond', long_name: '45 Bond', types: ['street_number']};
    const route = {short_name: 'Street', long_name: 'Street', types: ['route']};
    const city_component = {short_name: 'New York', long_name: 'New York', types: ['city']};
    const administrative_area_level_1 = {short_name: 'NY', long_name: 'New York', types: ['administrative_area_level_1']};
    const postal_code = {short_name: '10012', long_name: '10012', types: ['postal_code']};
    const geometry = {location: {lat: () => '44', lng: () => '32'}};

    expect(formatAddressForAPI({street_number, route, city: city_component, administrative_area_level_1, postal_code}, geometry)).toEqual({
      address1: `${street_number.short_name} ${route.short_name}`,
      city: city_component.short_name,
      state: administrative_area_level_1.short_name,
      zip_code: postal_code.short_name,
      latitude: '44',
      longitude: '32'
    });
  });
});

describe('formatAddressComponent', () => {
  it('returns long name if not specified', () => {
    const street_number = {short_name: '45 Bond', long_name: '45 Bond', types: ['street_number']};
    expect(formatAddressComponent(street_number)).toEqual('45 Bond');
  });
  it('returns short name if specified', () => {
    const street_number = {short_name: '45', long_name: '45 Bond', types: ['street_number']};
    expect(formatAddressComponent(street_number, 'short_name')).toEqual('45');
  });
  it('returns empty string if component undefined', () => {
    const nothing = undefined;
    expect(formatAddressComponent(nothing, 'short_name')).toEqual('');
  });
});

describe('makeFuzzyMatcher', () => {
  const fuzzyMatcher = makeFuzzyMatcher();
  it('returns true if chars of string2 appear case insensitive at the start of string1', () => {
    const string1 = '45 Bond Street';
    const string2 = '45 b';
    expect(fuzzyMatcher(string1, string2)).toEqual(true);
  });
  it('returns true if chars of string2 appear case insensitive internal to string1 with 1 char of terminal fuzziness', () => {
    const string1 = '45 Bond Street';
    const string2 = 'bondf';
    expect(fuzzyMatcher(string1, string2)).toEqual(true);
  });
  it('returns false if more than one character at the end of string2 is not within string1', () => {
    const string1 = '45 Bond Street';
    const string2 = '45 bfr';
    expect(fuzzyMatcher(string1, string2)).toEqual(false);
  });
  it('returns false if internal string2 character breaks continuous match', () => {
    const string1 = '45 Bond Street';
    const string2 = '45 Bfnd Street';
    expect(fuzzyMatcher(string1, string2)).toEqual(false);
  });
});

describe('nonCurrentAddresses', () => {
  it('returns empty array if addresses not defined', () => {
    const addresses = undefined;
    const current_address = address_factory.build();
    expect(nonCurrentAddresses(addresses, current_address)).toEqual([]);
  });
  it('returns whole array if current_address not defined', () => {
    const addresses = [address_factory.build()];
    const current_address = undefined;
    expect(nonCurrentAddresses(addresses, current_address)).toEqual(addresses);
  });
  it('returns array sans current_address if present within addresses', () => {
    const current_address = address_factory.build({local_id: 'current_id'});
    const other_address = address_factory.build({local_id: 'other_id'});
    expect(nonCurrentAddresses([current_address, other_address], current_address)).toEqual([other_address]);
  });
});
