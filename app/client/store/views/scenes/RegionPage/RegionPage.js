import React, { Fragment } from 'react';

import { FeaturedProducts } from './FeaturedProducts/FeaturedProducts';
import { HowItWorks } from './HowItWorks/HowItWorks';
import { RegionalStores } from './RegionalStores/RegionalStores';
import { RegionFaq } from './RegionFaq/RegionFaq';
import { RegionInfo } from './RegionInfo/RegionInfo';
import { RegionsHero } from './RegionsHero/RegionsHero';
import { RegionTestimonials } from './RegionTestimonials/index';

export const RegionPage = ({
  image,
  region,
  suppliers
}) =>
  (
    <Fragment>
      <RegionsHero
        image={image}
        {...region} />
      <HowItWorks />
      <RegionalStores
        suppliers={suppliers}
        region={region} />
      <RegionInfo
        {...region} />
      <FeaturedProducts
        {...region} />
      <RegionFaq region={region} />
      <RegionTestimonials
        name={region.name} />
    </Fragment>
  );
