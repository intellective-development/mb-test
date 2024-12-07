// @flow

import * as React from 'react';
import cn from 'classnames';

// TODO: support for default + override hover class?

type MBTouchableProps = {
  disabled?: boolean,
  onClick?: Function,
  className?: string,
  children: React.Node
};

class MBTouchable extends React.PureComponent<MBTouchableProps> {
  handleClick = () => {
    if (!this.props.disabled && this.props.onClick) this.props.onClick();
  }

  render(){
    const {disabled, className, children, ...rest_props} = this.props;
    const classes = cn('el-touchable', {'el-touchable--disabled': disabled}, className);

    return (
      <div
        role="button"
        tabIndex="-1"
        {...rest_props}
        className={classes}
        onClick={this.handleClick}>
        {children}
      </div>
    );
  }
}

export default MBTouchable;
