import React from 'react';
import { storiesOf } from '@storybook/react';
import { FilterGroup } from './FilterGroup';
import '../../../../../../assets/fonts/avenir-font-family.css';

const terms = [
  {
    count: 1,
    description: 'B&S Zeeman Wine & Spirits',
    term: 1
  },
  {
    count: 1,
    description: 'Bowery & Vine',
    term: 2
  },
  {
    count: 1,
    description: 'Broadway Spirits',
    term: 3
  },
  {
    count: 1,
    description: 'East Houston St Wine & Liquor',
    term: 4
  },
  {
    count: 1,
    description: 'House Wine',
    term: 5
  },
  {
    count: 1,
    description: 'New York Wine Exchange',
    term: 6
  },
  {
    count: 1,
    description: 'Rosetta Wines',
    term: 7
  },
  {
    count: 1,
    description: 'Urban Artisinal Wines & Craft Spirits',
    term: 8
  }
];

storiesOf('ProductList/FilterView', module)
  .add('FilterGroup', () => (
    <FilterGroup
      display_name="Stores"
      terms={terms} />
  ));
