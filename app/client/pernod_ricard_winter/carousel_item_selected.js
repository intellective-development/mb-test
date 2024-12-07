import * as React from 'react';
import SingleProductPlacement from './single_product_placement';

const CarouselItemSelected = ({item}) => {
  return (
    <div className="row carousel-selected-container">
      <div className="columns medium-7 small-12 carousel-selected-container">
        <div className="title">{item.title}</div>
        <div className="image"><img src={item.img_url} alt={item.title} /></div>
        <ul className="ingredients-list">
          {item.ingredients.map((ingredient, i) => {
            return <li key={i}><bullet>&bull;</bullet><span dangerouslySetInnerHTML={{__html: ingredient}} /></li>;
          })}
        </ul>
        <div className="copy">{item.copy}</div>
        <SingleProductPlacement item={item} />
      </div>
    </div>
  );
};

export default CarouselItemSelected;
