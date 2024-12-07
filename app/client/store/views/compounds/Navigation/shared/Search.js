// @flow

import * as React from 'react';
import { connect } from 'react-redux';

import type { AutocompleteResultType, AutocompleteResult } from 'store/business/autocomplete';
import {autocomplete_actions, autocomplete_constants, autocomplete_selectors} from 'store/business/autocomplete';
import { dispatchAction } from 'shared/dispatcher';
import { MBKeypressHandler, MBClickOutside } from '../../../elements';
import Autocomplete from './AutocompleteDropdown';
import './Search.scss';

type State = {
  show_dropdown: boolean,
  query: string,
  selected_index?: number,
}

export type InputProps = {
  is_loading: boolean,
  value: string,
  clear: () => void,
  onKeyDown: (SyntheticKeyboardEvent<HTMLInputElement>) => void,
  onChange: (SyntheticKeyboardEvent<HTMLInputElement>) => void,
  onFocus: (SyntheticKeyboardEvent<HTMLInputElement>) => void,
  onBlur: (SyntheticKeyboardEvent<HTMLInputElement>) => void
}

type Props = {
  is_loading: boolean,
  results: AutocompleteResult[],
  fetchAutocompleteResults: typeof autocomplete_actions.attemptAutocomplete,
  onClose?: () => void,
  renderInput: (props: InputProps) => React.Node
}

const navigateToRoute = (route: string, query: string, category?: string) => dispatchAction({
  actionType: 'navigate',
  destination: `${route}?q=${query}&sc=${category}`, // Query params are for tracking purposes
  options: {trigger: true}
});

// State helpers
const getSelectedResult = (state: State, props: Props) => {
  const { query, selected_index } = state;
  const { results } = props;
  const result = results[selected_index];

  if (result === undefined){
    return { name: query };
  }

  return result;
};

// State manipulation
// Query
const updateQuery = (value: string) => (_state: State, _props: Props) => ({ query: value });
const resetQuery = updateQuery('');
// Selected index
const updateIndex = (value?: number) => (_state: State, _props: Props) => ({ selected_index: value });
const resetIndex = updateIndex();
const moveIndexDown = (state: State, props: Props) => {
  const { selected_index } = state;
  const { results } = props;

  switch (selected_index){
    // At beginning
    case undefined:
      return { selected_index: 0 };

    // At end
    case (results.length - 1):
    case -1:
      return { selected_index: undefined };

    // In middle
    default:
      return { selected_index: selected_index + 1 };
  }
};
const moveIndexUp = (state: State, props: Props) => {
  const { selected_index } = state;
  const { results } = props;

  switch (selected_index){
    // At beginning
    case 0:
      return { selected_index: undefined };

    // At end
    case undefined:
      return { selected_index: results.length - 1 };

    // In middle
    default:
      return { selected_index: selected_index - 1 };
  }
};
// Dropdown
const updateDropdownVisibility = (is_showing: boolean) => (_state: State, _props: Props) => ({ show_dropdown: is_showing });
const showDropdown = updateDropdownVisibility(true);
const hideDropdown = updateDropdownVisibility(false);
// Reset
const resetState = () => ({
  ...hideDropdown(),
  ...resetIndex(),
  ...resetQuery()
});

class SearchInput extends React.Component<Props, State> {
  state = resetState();

  clear = () => {
    this.setState(resetQuery);
    this.setState(resetIndex);
  }

  handleInputChange = (event: SyntheticKeyboardEvent<HTMLInputElement>) => {
    const query = event.currentTarget.value;
    this.setState(updateQuery(query));
    this.setState(resetIndex);
    this.props.fetchAutocompleteResults(query);
  }

  showDropdown = () => {
    this.setState(showDropdown);
    this.setState(resetIndex);
  }

  hideDropdown = () => {
    this.setState(hideDropdown);
    this.setState(resetIndex);
    this.props.onClose && this.props.onClose();
  }

  moveDown = () => this.setState(moveIndexDown);
  moveUp = () => this.setState(moveIndexUp);

  submit = (event: SyntheticKeyboardEvent<HTMLInputElement>) => {
    const { selected_index, query } = this.state;
    const { results } = this.props;

    event.currentTarget.blur();
    this.setState(resetState);
    this.props.onClose && this.props.onClose();


    if (selected_index === undefined){
      navigateToRoute(`/store/search/${query}`, query);
    } else {
      const { type, permalink } = results[selected_index];
      this.selectResult(type, permalink, query);
    }
  }

  selectResult = (type: AutocompleteResultType, permalink: string, query: string) => {
    this.setState(resetState);
    this.props.onClose && this.props.onClose();
    navigateToRoute(`/store/${type}/${permalink}`, query, type);
  }

  isDropdownShowing = () => {
    const { show_dropdown, query } = this.state;
    return show_dropdown && query.length >= autocomplete_constants.MINIMUM_QUERY_LENGTH;
  }

  render(){
    const { is_loading, renderInput, results } = this.props;
    const { selected_index, query } = this.state;
    const show_dropdown = this.isDropdownShowing();
    const selected_result = getSelectedResult(this.state, this.props);
    const tagged_results = results.map((result, index) => ({...result, is_selected: selected_index === index}));

    const Input = (
      <MBKeypressHandler
        key_handlers={{
          enter: this.submit,
          down_arrow: this.moveDown,
          up_arrow: this.moveUp
        }}
        render={
          ({ onKeyDown }) => renderInput({
            is_loading,
            value: selected_result.name,
            clear: this.clear,
            onKeyDown,
            onChange: this.handleInputChange,
            onFocus: this.showDropdown,
            onBlur: this.hideDropdown
          })
        } />
    );

    return (
      <MBClickOutside handleClickOutside={this.hideDropdown} disableOnClickOutside={!show_dropdown}>
        <div className="cmSearch__ClickOutsideTarget">
          {Input}
          <Autocomplete
            show={show_dropdown}
            results={tagged_results}
            query_string={query}
            selectResult={this.selectResult} />
        </div>
      </MBClickOutside>
    );
  }
}

const SearchInputSTP = (state) => ({
  results: autocomplete_selectors.getResults(state),
  is_loading: autocomplete_selectors.isFetching(state)
});

const SearchInputDTP = {
  fetchAutocompleteResults: autocomplete_actions.attemptAutocomplete
};

export default connect(SearchInputSTP, SearchInputDTP)(SearchInput);
