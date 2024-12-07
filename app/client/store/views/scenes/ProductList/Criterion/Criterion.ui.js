import React, { Fragment } from 'react';
import { storiesOf } from '@storybook/react';
import { Criterion } from './Criterion';
import '../../../../../../assets/fonts/avenir-font-family.css';

storiesOf('ProductList/Criterion', module)
  .add('filter', () => (
    <Fragment>
      <Criterion
        description="Champagne &amp; Sparkling"
        term="sparkling" />
      <Criterion
        description="Dessert"
        term="dessert" />
    </Fragment>
  ))
  .add('sort', () => (
    <Fragment>
      <Criterion
        description="Price - Low to High"
        group="sort-criterion"
        term="price_asc"
        type="radio" />
      <Criterion
        description="Price - High to Low"
        group="sort-criterion"
        term="price_desc"
        type="radio" />
    </Fragment>
  ));
