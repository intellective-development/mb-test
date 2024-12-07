import React from 'react';
import RChips from 'react-chips';

const Chips = ({ label, input, className, ...props }) => {
  return (
    <div className={`field-group ${className}`}>
      <label htmlFor={props.id || input.name}>{label}</label>
      <RChips
        createChipKeys={[13, ',']}
        id={input.name}
        {...input}
        {...props}
        value={input.value || []} />
    </div>
  );
};

export default Chips;
