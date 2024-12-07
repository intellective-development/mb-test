import React from 'react';
import { storiesOf } from '@storybook/react';
import { SortView } from './SortView';

storiesOf('ProductList/SortView', module)
  .add('SortView', () => (
    <SortView
      position="left" />
  ));
