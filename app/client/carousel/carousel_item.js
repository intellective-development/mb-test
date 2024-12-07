// @flow
import * as React from 'react';

// TODO: consider consolidating activeItem, previousActiveItem and nextActiveItem into an enum
type CarouselItemProps = {
  children: React.Node,
  activeItem: boolean,
  previousActiveItem: boolean,
  nextActiveItem: boolean
}
const CarouselItem = ({children, activeItem, nextActiveItem, previousActiveItem}: CarouselItemProps) => {
  let class_name;
  if (activeItem){
    class_name = 'activeStyle';
  } else if (nextActiveItem){
    class_name = 'willBeActiveStyle';
  } else if (previousActiveItem){
    class_name = 'wasActiveStyle';
  } else {
    class_name = 'itemStyle';
  }

  return (
    <div className={class_name}>
      {children}
    </div>
  );
};

export default CarouselItem;
