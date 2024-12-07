// @flow

import * as React from 'react';
import CarouselItem from './carousel_item';

type CarouselProps = {delay: number, children?: React.Node};
type CarouselState = {itemCount: number, activeItem: number};
class Carousel extends React.Component<CarouselProps, CarouselState> {
  static defaultProps = { delay: 5000 }
  interval: number

  constructor(props: CarouselProps){
    super(props);
    const itemCount = React.Children.count(props.children);
    this.state = {
      itemCount: itemCount,
      activeItem: 0
    };
  }

  componentDidMount(){
    this.interval = setInterval(this.slide, this.props.delay);
  }

  componentWillUnmount(){
    clearInterval(this.interval);
  }

  nextActiveItem = (activeItem: number, itemCount: number) => (
    (activeItem + 1) % itemCount
  )

  previousActiveItem = (activeItem: number, itemCount: number) => (
    (activeItem + (itemCount - 1)) % itemCount
  )

  slide = () => {
    this.setState({
      activeItem: (this.state.activeItem + 1) % this.state.itemCount
    });
  }

  carouselItems = () => {
    const next_active_item = this.nextActiveItem(this.state.activeItem, this.state.itemCount);
    const previous_active_item = this.previousActiveItem(this.state.activeItem, this.state.itemCount);

    return (
      React.Children.map(this.props.children, (child, index) => (
        <CarouselItem
          activeItem={index === this.state.activeItem}
          nextActiveItem={index === next_active_item}
          previousActiveItem={index === previous_active_item}>
          {child}
        </CarouselItem>
      ))
    );
  };

  render(){
    return (
      <div className="carousel-content-container">
        {this.carouselItems()}
      </div>
    );
  }
}

export default Carousel;
