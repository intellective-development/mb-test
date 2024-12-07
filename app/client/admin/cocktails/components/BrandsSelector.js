import React from 'react';
import Autosuggest from 'react-autosuggest';
import { searchBrands } from '../../admin_api';

const getSuggestionValue = suggestion => suggestion.name;

// Use your imagination to render suggestions.
const renderSuggestion = suggestion => (
  <div>
    {suggestion.name}
  </div>
);

class BrandsSelector extends React.Component {
  state = {
    loading: false,
    searchValue: null,
    suggestions: []
  }

  onChange(e, { newValue }){
    this.setState({
      searchValue: newValue || ' '
    });
    if (newValue === ''){
      this.props.input.onChange({});
    }
  }

  onSelect(event, { suggestion }){
    this.props.input.onChange(suggestion);
  }

  onSuggestionsFetchRequested({ value }){
    this.setState({
      loading: true
    });
    searchBrands(value.trim())
      .then(suggestions => {
        this.setState({ suggestions, loading: false });
      });
  }

  onSuggestionsClearRequested(){
    this.setState({
      suggestions: []
    });
  }

  render(){
    const { label, input: fieldInput, className, ...props } = this.props;
    const { suggestions, searchValue } = this.state;
    return (
      <div className={`field-group ${className}`}>
        <label htmlFor={fieldInput.name}>{label}</label>
        <Autosuggest
          suggestions={suggestions}
          getSuggestionValue={getSuggestionValue}
          renderSuggestion={renderSuggestion}
          onSuggestionSelected={this.onSelect.bind(this)}
          onSuggestionsFetchRequested={this.onSuggestionsFetchRequested.bind(this)}
          onSuggestionsClearRequested={this.onSuggestionsClearRequested.bind(this)}
          inputProps={{
            id: `${props.id || fieldInput.name}`,
            ...props,
            value: searchValue || fieldInput.value.name || '',
            onChange: this.onChange.bind(this)
          }}
          {...fieldInput} />
      </div>
    );
  }
}

export default BrandsSelector;
