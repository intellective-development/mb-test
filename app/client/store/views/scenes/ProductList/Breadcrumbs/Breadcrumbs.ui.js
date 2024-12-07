import React from 'react';
import { storiesOf } from '@storybook/react';
import { Breadcrumbs } from './Breadcrumbs';

storiesOf('ProductList', module)
  .add('FacetBar', () => (
    <Breadcrumbs />
  ));
