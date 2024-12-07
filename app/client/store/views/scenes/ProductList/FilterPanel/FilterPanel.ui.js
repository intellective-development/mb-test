import React from 'react';
import { storiesOf } from '@storybook/react';
import { FilterPanel } from './FilterPanel';
import '../../../../../../assets/fonts/avenir-font-family.css';

export const facets = [
  {
    display_name: 'Stores',
    index: 0,
    multi: true,
    name: 'suppliers',
    prefer_alpha_sort: false,
    terms: [
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
    ],
    total: null,
    type: null
  },

  // {
  //   "display_name": "Subtype",
  //   "name": "hierarchy_subtype"
  // },
  {
    display_name: 'Category',
    index: 2,
    multi: true,
    name: 'hierarchy_type',
    prefer_alpha_sort: false,
    terms: [
      {
        count: 118,
        description: 'Red',
        term: 'wine-red'
      },
      {
        count: 72,
        description: 'White',
        term: 'wine-white'
      },
      {
        count: 32,
        description: 'Champagne & Sparkling',
        term: 'wine-sparkling'
      },
      {
        count: 12,
        description: 'Rose',
        term: 'wine-rose'
      },
      {
        count: 10,
        description: 'Sake',
        term: 'wine-sake'
      },
      {
        count: 8,
        description: 'Fortified',
        term: 'wine-fortified'
      },
      {
        count: 2,
        description: 'Dessert',
        term: 'wine-dessert'
      }
    ],
    total: null,
    type: 'product_type'
  },
  {
    display_name: 'Size',
    index: null,
    multi: false,
    name: 'item_volumes',
    prefer_alpha_sort: false,
    terms: [
      {
        count: 100,
        description: '12 oz',
        term: '12.0OZ'
      },
      {
        count: 20,
        description: '1 L',
        term: '1.0L'
      },
      {
        count: 17,
        description: '2 L',
        term: '2.0L'
      },
      {
        count: 8,
        description: '750 mL',
        term: '750.0ML'
      },

      // {
      //   "count": 6,
      //   "description": "",
      //   "term": ""
      // },
      {
        count: 6,
        description: '11.2 oz',
        term: '11.2OZ'
      },
      {
        count: 3,
        description: '1.75 L',
        term: '1.75L'
      },
      {
        count: 3,
        description: '59 oz',
        term: '59.0OZ'
      },
      {
        count: 2,
        description: '16.9 oz',
        term: '16.9OZ'
      },
      {
        count: 2,
        description: '64 oz',
        term: '64.0OZ'
      }
    ],
    total: null,
    type: null
  },
  {
    display_name: 'Country',
    index: 4,
    multi: true,
    name: 'country',
    prefer_alpha_sort: true,
    terms: [
      {
        count: 78,
        description: 'United States',
        term: 'United States'
      },
      {
        count: 43,
        description: 'France',
        term: 'France'
      },
      {
        count: 26,
        description: 'Italy',
        term: 'Italy'
      },
      {
        count: 13,
        description: 'Spain',
        term: 'Spain'
      },
      {
        count: 12,
        description: 'Argentina',
        term: 'Argentina'
      },
      {
        count: 11,
        description: 'Chile',
        term: 'Chile'
      },
      {
        count: 10,
        description: 'South Africa',
        term: 'South Africa'
      },
      {
        count: 9,
        description: 'Japan',
        term: 'Japan'
      },
      {
        count: 9,
        description: 'New Zealand',
        term: 'New Zealand'
      },
      {
        count: 8,
        description: 'Portugal',
        term: 'Portugal'
      },
      {
        count: 5,
        description: 'Israel',
        term: 'Israel'
      }
    ],
    total: null,
    type: null
  },
  {
    display_name: 'Container',
    index: null,
    multi: false,
    name: 'container_types',
    prefer_alpha_sort: false,
    terms: [
      {
        count: 149,
        description: 'Bottle',
        term: 'BOTTLE'
      },
      {
        count: 17,
        description: 'Can',
        term: 'CAN'
      }
    ],
    total: null,
    type: null
  },
  {
    display_name: 'Price',
    index: 8,
    multi: false,
    name: 'price',
    prefer_alpha_sort: false,
    terms: [
      {
        count: 244,
        description: 'Under $20',
        term: '*-20.0'
      },
      {
        count: 150,
        description: '$20 – $40',
        term: '20.0-40.0'
      },
      {
        count: 139,
        description: '$40 And Up',
        term: '40.0-*'
      }
    ],
    total: null,
    type: null
  }

  // {
  //   "display_name": "Delivery",
  //   "name": "delivery_type"
  // }
];

storiesOf('ProductList/FilterView', module)
  .add('FilterPanel', () => (
    <FilterPanel
      facets={facets}
      position="left"
      toggle
      toggleLeft={35} />
  ));
