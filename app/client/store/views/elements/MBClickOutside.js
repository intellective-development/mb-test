// @flow

import * as React from 'react';
import onClickOutside from 'react-onclickoutside';

// This element wraps our third party click outside handler.
// Rather than exposing that functionality as an HOC, like the library, we use a small wrapping component.

type MBClickOutsideProps = {
  handleClickOutside: () => any,
  children: React.Node,

  // This is consumed by onClickOutside.
  // When dealing with a visible/invisible ui element, we generally recommend it be set to false when the component is invisible
  disableOnClickOutside?: boolean
}

class MBClickOutside extends React.Component<MBClickOutsideProps> {
  handleClickOutside(){
    this.props.handleClickOutside();
  }

  render(){
    return this.props.children;
  }
}

export default onClickOutside(MBClickOutside);
