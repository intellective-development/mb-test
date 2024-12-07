import React from 'react';
import { connect } from 'react-redux';

const Tool = ({ name, icon }) => {
  return (
    <li className="tool">
      { icon && icon.image_url ? <img src={icon.image_url} alt="tool icon" className="tool-icon" /> : null }
      <div>{name}</div>
    </li>
  );
};

export default connect()(Tool);
