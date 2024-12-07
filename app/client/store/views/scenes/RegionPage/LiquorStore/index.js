import { compact, get, join } from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';

import { LiquorStore as Element } from './LiquorStore';

export const LiquorStore = ({
  address,
  display_name,
  permalink,
  profile,
  region
}) => {
  const phone = get(address, 'phone').replace(/\D/g, '');

  const streetAddress = join(
    compact([
      get(address, 'address1'),
      get(address, 'address2')
    ]),
    ', '
  );

  const telephone = [
    '(',
    phone.slice(-10, -7),
    ') ',
    phone.slice(-7, -4),
    '-',
    phone.slice(-4)
  ].join('');

  const url = join([
    'https://minibardelivery.com',
    'partner',
    get(region, 'slug'),
    permalink
  ], '/');

  return (
    <Element
      addressLocality={get(address, 'city')}
      addressRegion={get(address, 'state_name')}
      categories={get(profile, 'categories')}
      latitude={get(address, 'latitude')}
      longitude={get(address, 'longitude')}
      name={display_name}
      postalCode={get(address, 'zip_code')}
      streetAddress={streetAddress}
      telephone={telephone}
      url={url} />
  );
};

LiquorStore.displayName = 'LiquorStore';

LiquorStore.propTypes = {
  address: PropTypes.shape({
    address1: PropTypes.string,
    address2: PropTypes.string,
    city: PropTypes.string,
    latitude: PropTypes.number,
    longitude: PropTypes.number,
    phone: PropTypes.string,
    state_name: PropTypes.string,
    zip_code: PropTypes.string
  }),
  display_name: PropTypes.string,
  permalink: PropTypes.string,
  profile: PropTypes.shape({
    categories: PropTypes.shape({
      beer: PropTypes.oneOfType([
        PropTypes.number,
        PropTypes.string
      ]),
      liquor: PropTypes.oneOfType([
        PropTypes.number,
        PropTypes.string
      ]),
      mixers: PropTypes.oneOfType([
        PropTypes.number,
        PropTypes.string
      ]),
      wine: PropTypes.oneOfType([
        PropTypes.number,
        PropTypes.string
      ])
    }).isRequired
  }),
  region: PropTypes.shape({
    slug: PropTypes.string
  })
};

export default LiquorStore;
