// @flow

import * as React from 'react';
// Originally grabbed from https://github.com/joshwnj/react-visibility-sensor/issues/10,
// but they don't support the offset which I would like for a more smooth scrolling experience
// They also don't use scroll events, which is a bit gross

type ScrollSensorProps = {|
  onChange: (boolean) => void,
  active: boolean,
  delay: number,
  bottomOffset: number,
  children: React.Node
|}

class ScrollSensor extends React.Component<ScrollSensorProps> {
  static displayName = 'VisibilitySensor';

  static defaultProps = {
    active: true,
    delay: 1000,
    bottomOffset: 0
  };

  lastValue: ?boolean;
  sensor_container_el: ?HTMLDivElement;


  componentDidMount(){
    if (this.props.active){
      this.startWatching();
    }
  }

  componentWillReceiveProps(nextProps){
    if (!this.props.active && nextProps.active){ // inactive -> active
      this.lastValue = null;
      this.startWatching();
    } else if (this.props.active && !nextProps.active){ // active -> inactive
      this.stopWatching();
    }
  }

  componentWillUnmount(){
    this.stopWatching();
  }

  startWatching = () => {
    window.onscroll = this.check;
  };

  stopWatching = () => {
    window.onscroll = null;
  };

  check = () => {
    const rect = this.sensor_container_el.getBoundingClientRect();
    const isVisible = (
      rect.top >= 0 &&
      rect.left >= 0 &&
      rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) + this.props.bottomOffset &&
      rect.right <= (window.innerWidth || document.documentElement.clientWidth)
    );

    // notify the parent when the value changes
    if (this.lastValue !== isVisible){
      this.lastValue = isVisible;
      this.props.onChange(isVisible);
    }
  };

  render(){
    return (
      <div ref={(el) => { this.sensor_container_el = el; }}>
        {this.props.children}
      </div>
    );
  }
}

export default ScrollSensor;
