// @flow

import { compact } from 'lodash';
import React, { useEffect } from 'react';
import I18n from 'store/localization';
import { MBCarousel } from 'store/views/elements';
import ShippingRequiredNotification from './ShippingRequiredNotification';
import TextBlock from './TextBlock';
import styles from './BrandDescription.scss';

type BrandDescriptionProps = {
  brand?: {
    name?: string,
    description?: string,
    image_path?: string,
    tags?: string[]
  }
}

const VINEYARD_SELECT_TAG = 'vineyard-select';

const BrandDescription = ({ brand }: BrandDescriptionProps) => {
  if (!brand) return null;

  const { name, description, image_path, tags = [] } = brand;
  const show_description = description && description.length;
  const hero_content = [{
    name: name,
    image_url: image_path
  }];

  const carousel = () => {
    if (!image_path || image_path.indexOf('missing.png') > -1) return null;
    return <MBCarousel content={hero_content} />;
  };

  useEffect(() => {
    if (show_description){
      document.querySelector('meta[name="description"]')
        .setAttribute('content', description);
    }
    document.title = compact([name, 'Minibar Delivery'])
      .join(' - ');
  }, [description, name]);

  return (
    <div className="cm-brand-description">
      <h1 className={styles.cmBrandDescription_Name}>
        {I18n.t('ui.brand_description.brand_name', { name })}
      </h1>
      { carousel() }
      <div>
        {show_description && (<TextBlock>{description}</TextBlock>)}
        <ShippingRequiredNotification show={tags.includes(VINEYARD_SELECT_TAG)} />
      </div>
    </div>
  );
};

export default BrandDescription;
