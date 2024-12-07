import React from 'react';
import { storiesOf } from '@storybook/react';
import { FilterView } from './FilterView';
import { facets } from '../FilterPanel/FilterPanel.ui';

storiesOf('ProductList/FilterView', module)
  .add('FilterView', () => (
    <FilterView
      facets={facets}
      position="left" />
  ));
