import React from 'react';
import { storiesOf } from '@storybook/react';
import { SortPanel } from './SortPanel';

storiesOf('ProductList/SortView', module)
  .add('SortPanel', () => (
    <SortPanel
      position="left"
      sortOptionId="popular_desc"
      toggle
      toggleLeft={35} />
  ));
