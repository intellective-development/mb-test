import React from 'react';
import { storiesOf } from '@storybook/react';
import { FacetBar } from './FacetBar';
import { facets } from '../FilterPanel/FilterPanel.ui';

storiesOf('ProductList', module)
  .add('FacetBar', () => (
    <FacetBar
      facets={facets} />
  ));
