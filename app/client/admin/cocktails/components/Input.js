import React from 'react';

const Input = ({ label, input: fieldInput, meta: { error }, className, ...props }) => {
  return (
    <div className={`field-group ${className}`}>
      <label htmlFor={props.id || fieldInput.name}>{label}</label>
      <input
        type="text"
        id={fieldInput.name}
        {...props}
        {...fieldInput} />
      <p className="text-error">{error}</p>
    </div>
  );
};

export default Input;
