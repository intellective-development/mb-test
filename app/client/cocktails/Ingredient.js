import React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';

const Ingredient = ({ name, qty, product }) => {
  return (
    <li>
      {qty} {!_.isEmpty(product) ? <a href={product && `${product}`}>{name}</a> : name }
    </li>
  );
};

export default connect()(Ingredient);
