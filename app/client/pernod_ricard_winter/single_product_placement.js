import * as React from 'react';
import SingleProductButton from './single_product_button';

const SingleProductPlacement = ({item}) => {
  return (
    <div className="single-product-container columns small-6">
      <div className="single-product-container_image">
        <img src={item.product_img_url} alt={item.product_name} />
      </div>
      <div className="single-product-container_title">{item.product_name}</div>
      <SingleProductButton url={item.product_url} />
    </div>
  );
};

export default SingleProductPlacement;
