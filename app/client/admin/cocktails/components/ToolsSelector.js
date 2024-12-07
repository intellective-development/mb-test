import React from 'react';
import Chips from 'react-chips';
import { searchToolsList } from '../../admin_api';

const renderChip = (item) => <CustomChip key={item.id}>{item.name}</CustomChip>;
const renderSuggestion = (item) => (<div key={item.id}>{item.name}</div>);

const ToolsSelector = ({ label, input: fieldInput, className, ...props }) => {
  return (
    <div className={`field-group ${className}`}>
      <label htmlFor={fieldInput.name}>{label}</label>
      <Chips
        onChange={fieldInput.onChange}
        value={fieldInput.value || []}
        fromSuggestionsOnly
        renderChip={renderChip}
        fetchSuggestions={searchToolsList}
        renderSuggestion={renderSuggestion}
        {...props} />
    </div>
  );
};

export default ToolsSelector;

const CustomChip = ({ index, onRemove, children }) =>
  (<div>{children} &nbsp;<span role="button" tabIndex={index} onClick={onRemove.bind(null, index)}>&times;</span>&nbsp;</div>);
