import * as React from 'react';

const CarouselItem = ({selected, item, onItemSelect}) => {
  const styles = {
    carouselItemStyle: {
      backgroundImage: `url(${item.thumbnail_url})`
    },
    selectedItemStyle: {
      backgroundColor: 'rgba(255, 255, 255, 0)'
    }
  };

  const { carouselItemStyle, selectedItemStyle } = styles;

  return (
    <div onClick={() => onItemSelect(item)} className="carousel-item" style={carouselItemStyle} >
      <div className="carousel-item_title_overlay" style={selected ? selectedItemStyle : null}>
        <div className="carousel-item_title_text">{item.title}</div>
      </div>
    </div>
  );
};

export default CarouselItem;
