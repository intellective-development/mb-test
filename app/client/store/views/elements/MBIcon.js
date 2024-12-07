// @flow

import * as React from 'react';
import cn from 'classnames';

// This is intended to work as a unified location for our most common, simple ui icons (x's, arrows, etc.)
// As such, it is responsible for resizing 2x assets.

type IconName =
'close'
| 'back'
| 'check'
| 'minibar_logo'
| 'down_arrow_red'
| 'clock'
| 'pin'
| 'clear'
| 'mobile.minibar_logo'
| 'mobile.pencil';

type MBIconProps = {
  className?: string,
  name: IconName
};

const MBIcon = ({name, className, ...rest_props}: MBIconProps) => {
  const icon_fragment = formatIconFragment(name);
  const classes = cn(`el-mbicon--${name}`, className);

  return (
    <img
      alt={name}
      {...rest_props}
      className={classes}
      src={`/assets/components/elements/mb-icon/${icon_fragment}.png`}
      srcSet={`/assets/components/elements/mb-icon/${icon_fragment}@2x.png 2x, ` +
              `/assets/components/elements/mb-icon/${icon_fragment}@3x.png 3x`} />
  );
};

export default MBIcon;

// helpers
const formatIconFragment = (icon_name: string) => icon_name.replace('.', '/');
