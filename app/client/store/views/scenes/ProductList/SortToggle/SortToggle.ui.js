import React from 'react';
import { storiesOf } from '@storybook/react';
import { SortToggle } from './SortToggle';

storiesOf('ProductList/SortView', module)
  .add('SortToggle', () => <SortToggle />);
