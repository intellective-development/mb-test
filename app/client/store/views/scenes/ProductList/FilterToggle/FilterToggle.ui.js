import React from 'react';
import { storiesOf } from '@storybook/react';
import { FilterToggle } from './FilterToggle';
import '../../../../../../assets/fonts/avenir-font-family.css';

storiesOf('ProductList/FilterView', module)
  .add('FilterToggle', () => <FilterToggle />);
