// @flow

import * as React from 'react';
import _ from 'lodash';
import cn from 'classnames';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import isMobile from 'store/business/utils/is_mobile';
import type { Address } from 'store/business/address';
import { user_selectors } from 'store/business/user';
import { supplier_selectors } from 'store/business/supplier';
import ErrorMessage from './ErrorMessage';
import { MBButton, MBInput, MBIcon } from '../../elements';
import type { GoogleAddress } from './utils';
import {
  addressToString,
  getAddressComponents,
  validateComponents,
  makeFuzzyMatcher,
  nonCurrentAddresses,
  uniqAddresses,
  getStoreableAddress
} from './utils';
import AddressDropdown from './AddressDropdown';


// TODO: In order to allow a full drop in react component experience, should just be instantiating from the top level
// view, in this case, store entry.

// NOTE: Only google places autocomplete results and recent addresses can be passed to the API

// The browser autofill suggestions ignore the autocomplete parameters apparenlty. On Chrome, changing
// the name of the input is seemingly enough to avoid the autocompletle from rendering, however it
// appears that Safari's autocomplete looks for possible autocomplete fields within the field's placeholder
// text as well. As a workaround we have inserted a "no-width whitespace" character (\u200B) into the word "address"
const AUTOFILL_WORKAROUNDS = {
  input_name: 'addres-input',
  placeholder_text: 'Enter a delivery add\u200Bress to shop'
};
export const INPUT_ID = AUTOFILL_WORKAROUNDS.input_name;

const ENTER_KEY_CODE = 13;
const UP_ARROW_KEY_CODE = 38;
const DOWN_ARROW_KEY_CODE = 40;
const default_state = {
  error_type: '',
  loading: false,
  input_address: '', // raw string value of address input
  google_addresses: [],
  selected_index: 0,
  pristine: true
};

type AddressEntryProps = {|
  autofocus: boolean,
  recent_addresses: Array<Address>,
  submitAddress: (Address, resetState?: () => void, destinationLocation?: string) => void,
  current_address: Address, // the address the user currently has in use in the store
  can_submit_current?: boolean,
  submit_button_text?: string,
  button_hidden: boolean,
  show_placeholder?: boolean
|};
type AddressEntryState = {|
  error_type: string,
  loading: boolean,
  pristine: boolean,
  input_address: string,
  google_addresses: Array<GoogleAddress>, // google places autocomplete result objects
  filtered_recent_addresses: Array<Address>,
  selected_index: number
|};
class AddressEntry extends React.Component<AddressEntryProps, AddressEntryState> {
  static defaultProps = {
    autofocus: true,
    recent_addresses: [],
    current_address: {},
    can_submit_current: true,
    submit_button_text: 'Go',
    button_hidden: false
  }

  autocomplete_service: any
  places_service: any
  fuzzyMatcher: any
  input_el: ?HTMLInputElement
  input_container_el: ?HTMLDivElement

  constructor(props: AddressEntryProps){
    super(props);
    this.state = this.initialStateFromProps(props);
  }

  componentDidMount(){
    window.addEventListener('click', this.handleContainerClick, false);
    if (_.get(global, 'google.maps.places.AutocompleteService')){
      this.autocomplete_service = new global.google.maps.places.AutocompleteService();
      this.places_service = new global.google.maps.places.AutocompleteService();
      this.fuzzyMatcher = makeFuzzyMatcher();
    }

    if (_.isEmpty(this.props.current_address) && !isMobile() && this.input_el && this.props.autofocus){
      setTimeout(() => this.input_el && this.input_el.focus(), 0);
    }
  }
  componentWillReceiveProps(next_props: AddressEntryProps){
    if (this.props.current_address.local_id !== next_props.current_address.local_id && !this.state.loading){
      this.setState(this.initialStateFromProps(next_props));
    }
  }
  componentWillUnmount(){
    window.removeEventListener('click', this.handleContainerClick, false);
  }

  initialStateFromProps = (next_props: AddressEntryProps) => {
    const first_recent_address = next_props.recent_addresses && next_props.recent_addresses[0];
    return {
      ...default_state,
      input_address: addressToString(next_props.current_address || first_recent_address || {}),
      filtered_recent_addresses: this.filterRecentAddresses('', next_props.recent_addresses, next_props.current_address)
    };
  }

  handleContainerClick = (event: Object) => {
    const is_event_outside_element = !this.input_container_el.contains(event.target); // can't use input ref because it doesn't include clear button
    is_event_outside_element ? this.resetState() : setTimeout(() => this.input_el && this.input_el.focus(), 0);
  }

  resetState = () => {
    setTimeout(() => this.input_el && this.input_el.blur(), 0);
    this.setState(this.initialStateFromProps(this.props));
  }

  clearAddress = () => {
    setTimeout(() => this.input_el && this.input_el.focus(), 0);
    this.setState({...this.initialStateFromProps(this.props), pristine: false, input_address: ''}); // overwrite input value
  }

  filterRecentAddresses = (address_string, recent_addresses, current_address) => {
    const non_current = nonCurrentAddresses(recent_addresses, current_address);
    const non_current_matches = non_current.filter(a => (
      !address_string || this.fuzzyMatcher(a.address1, address_string) // NOTE: only matching on address1 if non-empty input
    ));
    return uniqAddresses(non_current_matches).slice(0, 5); // first 5 uniq, non-current, recent addresses fuzzily matching user input
  }

  debouncedInputHandler = _.debounce(this.handleInputChange, 1000)

  debounceInputChange = (event: Object) => {
    event.persist();
    this.setState({input_address: event.target.value});
    this.debouncedInputHandler(event);
  }

  handleInputChange(event: Object){
    const address_string = event.target.value;
    if (!_.isEmpty(address_string)){
      const filtered_recent_addresses = this.filterRecentAddresses(address_string, this.props.recent_addresses, this.props.current_address);
      this.setState({filtered_recent_addresses, selected_index: 0});
      this.autocomplete_service.getPlacePredictions({input: address_string, types: ['geocode']}, (gas) => {
        if (gas){
          this.setState({google_addresses: gas });
        } else {
          const places_service = new global.google.maps.places.PlacesService(document.createElement('div'));
          const structure_format = ({ formatted_address, ...rest }) => ({
            ...rest,
            structured_formatting: {
              main_text: formatted_address
            }
          });
          places_service.textSearch({ query: address_string }, (result) => {
            this.setState({google_addresses: result.map(structure_format) || [] });
          });
        }
      });
    } else {
      this.clearAddress();
    }
  }
  handleInputFocus = (event) => {
    if (this.state.pristine) this.setState({pristine: false});
    event.target.select();
  }

  // TODO: make sure not cycling through non filtered recent_addresses
  changeSelectedBy = (distance: number) => {
    const {filtered_recent_addresses, selected_index, google_addresses} = this.state;
    // don't allow access to more than 5 recent address options
    const recent_address_limit = filtered_recent_addresses.length >= 5 ? 5 : filtered_recent_addresses.length;
    // options are ordered as follows [user_input, ...filtered_recent_addresses, ...google_addresses]
    const option_count = 1 + recent_address_limit + google_addresses.length;
    // the next index should be between 0 and option_count w/ wrapping
    const next_index = ((selected_index + option_count) + distance) % option_count;
    this.setState({selected_index: next_index});
  }

  addressFromIndex = (index: number) => {
    const {filtered_recent_addresses, google_addresses} = this.state;
    if (index > 0 && index <= filtered_recent_addresses.length){
      return filtered_recent_addresses[index - 1];
    } else if (index > filtered_recent_addresses.length){
      return google_addresses[index - (1 + filtered_recent_addresses.length)];
    } else {
      return null;
    }
  }

  // TODO: abstract key handler into helper, maybe of the form:
  // handler = makeKeyPressHandler({key: 'up_arrow', handler: this.increment, propagate: true}, ...})
  handleKeyDown = (event: Object) => {
    if (this.state.pristine) this.setState({pristine: false});
    if (event.keyCode === UP_ARROW_KEY_CODE){ // up-arrow
      event.stopPropagation();
      event.preventDefault();
      this.changeSelectedBy(-1);
    } else if (event.keyCode === DOWN_ARROW_KEY_CODE){ // down-arrow
      event.stopPropagation();
      event.preventDefault();
      this.changeSelectedBy(1);
    } else if (event.keyCode === ENTER_KEY_CODE){ // enter
      // don't submit current_address when !can_submit_current
      if (this.state.selected_index !== 0 || _.isEmpty(this.props.current_address) || this.props.can_submit_current){
        this.submitIndex(this.state.selected_index);
      }
    }
  }

  submitIndex = (index: number) => {
    this.setState({loading: true, selected_index: index, pristine: true}); // ensure the selected index and input value reflect address selection
    if (index === 0){ // user input or current address
      this.trySubmitCurrent();
    } else { // past user address or google result
      const selected_address = this.addressFromIndex(index);
      this.submitAddress(selected_address);
    }
  }

  trySubmitCurrent = () => {
    const {input_address} = this.state;
    // submit current_address if input is equal to current_address string
    if (!_.isEmpty(this.props.current_address) && input_address === addressToString(this.props.current_address)){
      this.props.submitAddress(this.props.current_address, this.resetState);
    } else { // show error if attempting to submit raw user input (non current_address), still show dropdown options present
      this.setState({loading: false, pristine: false, error_type: _.isEmpty(input_address) ? 'no_address' : 'non_suggested_address'});
    }
  }

  submitAddress = (address: Address | GoogleAddress) => {
    if (address && address.place_id){ // is google result
      const places_service = new global.google.maps.places.PlacesService(document.getElementById('google_places_target'));
      places_service.getDetails({placeId: address.place_id}, response => {
        const address_components = response && getAddressComponents(response.address_components);
        if (address_components && validateComponents(address_components)){
          const storeable_address = getStoreableAddress(response, []);
          this.props.submitAddress(storeable_address, this.resetState, location.pathname);
        } else { // nuke input and show error if not a street address or place not found
          this.setState({...this.initialStateFromProps(this.props), error_type: 'no_street'});
        }
      });
    } else { // is past user address
      this.props.submitAddress(address, this.resetState, location.pathname);
    }
  }

  render(){
    const { current_address, submit_button_text, can_submit_current, button_hidden, show_placeholder } = this.props;
    const { pristine, input_address, google_addresses, error_type, selected_index, filtered_recent_addresses, loading } = this.state;

    const show_loading = loading || show_placeholder;
    const button_disabled = show_placeholder || (selected_index === 0 && !_.isEmpty(current_address) && !can_submit_current);
    const show_dropdown = !pristine && !_.isEmpty([...filtered_recent_addresses, ...google_addresses]);

    return (
      <div
        className={cn('cm-ae-container', {error: !!error_type})}
        id="address-entry"
        ref={(el) => { this.input_container_el = el; }} >
        <ErrorMessage message_type={error_type} />
        <div className="cm-ae-input__row" >
          <div className="cm-ae-input__container">
            <MBIcon name="pin" className="cm-ae-input__pin_icon" />
            <MBInput.Input
              id={INPUT_ID}
              disabled={show_placeholder}
              required
              type="text"
              name={AUTOFILL_WORKAROUNDS.input_name}
              className="cm-ae-input"
              placeholder={show_placeholder ? 'Loading...' : AUTOFILL_WORKAROUNDS.placeholder_text}
              value={selected_index === 0 ? input_address : addressToString(this.addressFromIndex(selected_index))}
              autoComplete="off"
              onFocus={this.handleInputFocus}
              onKeyDown={this.handleKeyDown}
              onChange={this.debounceInputChange}
              inputRef={el => { this.input_el = el; }} />
            <MBIcon
              name="clear"
              className={cn('cm-ae-input__close_button', {hidden: _.isEmpty(input_address), loading: show_loading})}
              onClick={this.clearAddress} />
            <span className={cn('cm-ae-input__loader', {button_hidden, loading: show_loading})} />
            <AddressDropdown
              submitOption={this.submitIndex}
              selected_index={selected_index}
              google_addresses={google_addresses}
              recent_addresses={filtered_recent_addresses}
              input_address={input_address}
              visible={show_dropdown} />
          </div>
          <MBButton
            size="tall"
            className={cn('cm-ae-button', {busy: show_loading, button_hidden})}
            id="address-button"
            onClick={() => this.submitIndex(this.state.selected_index)}
            disabled={button_disabled}>
            {submit_button_text}
            <div className="button__loader" />
          </MBButton>
        </div>
        <div id="google_places_target" />
      </div>
    );
  }
}

const AddressEntrySTP = () => {
  const findUser = Ent.find('user');
  const findAddress = Ent.find('address');

  return state => {
    const current_user = findUser(state, user_selectors.currentUserId(state));
    return {
      recent_addresses: findAddress(state, _.get(current_user, 'shipping_addresses') || []),
      supplier_fetch_loading: supplier_selectors.fetchLoading(state),
      supplier_fetch_waitlist_error: supplier_selectors.fetchError(state) && supplier_selectors.shouldJoinWaitlist(state)
    };
  };
};
const AddressEntryContainer = connect(AddressEntrySTP)(AddressEntry);

export default AddressEntryContainer;
