import * as React from 'react';
import CarouselItem from './carousel_item';

const CarouselContainer = (props) => {
  const carouselItems = props.items.map((item) => {
    return (
      <CarouselItem
        selected={props.selectedItem === item}
        onItemSelect={props.onItemSelect}
        item={item}
        key={item.title} />
    );
  });

  return (
    <div className="row">
      <div className="large-12 column carousel-container" >
        {carouselItems}
      </div>
    </div>
  );
};


export default CarouselContainer;
