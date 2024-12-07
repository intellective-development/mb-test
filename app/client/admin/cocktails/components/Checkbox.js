import React from 'react';

const handleChange = (input, { target: { checked }}) => {
  input.onChange(checked);
};

const Input = ({ label, input: fieldInput, className, ...props }) => {
  return (
    <div className={`field-group ${className}`}>
      <label htmlFor={props.id || fieldInput.name}>{label}</label>
      <input
        type="checkbox"
        {...fieldInput}
        id={fieldInput.name}
        onChange={handleChange.bind(null, fieldInput)}
        checked={fieldInput.value}
        {...props} />
    </div>
  );
};

export default Input;
