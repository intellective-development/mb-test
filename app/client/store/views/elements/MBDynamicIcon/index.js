// @flow

import * as React from 'react';
import bindClassNames from '../../../../shared/utils/bind_classnames';

import Bottle from './Bottle';
import Box from './Box';
import Can from './Can';
import CartDesktop from './CartDesktop';
import CartMobile from './CartMobile';
import Check from './Check';
import ChevronRight from './ChevronRight';
import ChevronLeft from './ChevronLeft';
import Email from './Email';
import FAQ from './FAQ';
import Hamburger from './Hamburger';
import Keg from './Keg';
import Phone from './Phone';
import Representative from './Representative';
import RightArrow from './RightArrow';
import Search from './Search';
import SMS from './SMS';
import XClose from './XClose';
import styles from './index.scss';

const cn = bindClassNames(styles);

const DEFAULT_VIEW_BOX = '0 0 32 32';

// TODO: look into the view box, this doesn't seem ideal.
// Should we perhaps store a base height/width or an aspect ratio for each of these?
const ICONS = {
  bottle: { Icon: Bottle, view_box: '0 0 120 120' },
  bottles: { Icon: Bottle, view_box: '0 0 120 120' },
  box: { Icon: Box, view_box: '0 0 120 120' },
  btl: { Icon: Bottle, view_box: '0 0 120 120' },
  can: { Icon: Can, view_box: '0 0 120 120' },
  cans: { Icon: Can, view_box: '0 0 120 120' },
  cart_desktop: { Icon: CartDesktop, view_box: '0 0 40 34' },
  cart_mobile: { Icon: CartMobile, view_box: DEFAULT_VIEW_BOX },
  check: { Icon: Check, view_box: DEFAULT_VIEW_BOX },
  chevron_right: { Icon: ChevronRight, view_box: DEFAULT_VIEW_BOX },
  chevron_left: { Icon: ChevronLeft, view_box: DEFAULT_VIEW_BOX },
  email: { Icon: Email, view_box: DEFAULT_VIEW_BOX },
  faq: { Icon: FAQ, view_box: DEFAULT_VIEW_BOX },
  hamburger: { Icon: Hamburger, view_box: DEFAULT_VIEW_BOX },
  keg: { Icon: Keg, view_box: '0 0 120 120' },
  phone: { Icon: Phone, view_box: DEFAULT_VIEW_BOX },
  representative: { Icon: Representative, view_box: DEFAULT_VIEW_BOX },
  right_arrow: { Icon: RightArrow, view_box: DEFAULT_VIEW_BOX },
  search: { Icon: Search, view_box: DEFAULT_VIEW_BOX },
  sms: { Icon: SMS, view_box: DEFAULT_VIEW_BOX },
  x_close: { Icon: XClose, view_box: DEFAULT_VIEW_BOX }
};

type IconName = $Keys<typeof ICONS>;

type MBDynamicIconProps = {
  name: IconName,
  className?: string,
  width: number,
  height: number,
  color?: 'white' | 'black' | 'red' | 'transparent'
};

const MBDynamicIcon = ({name, width, height, color, className, ...rest_props}: MBDynamicIconProps) => {
  const classes = cn('elMBDynamicIcon', className);
  const colorClass = cn({ [`elMBDynamicIcon__${String(color)}`]: color });
  const { Icon, view_box } = ICONS[name] || ICONS.bottle;

  return (
    <div {...rest_props} className={classes}>
      <svg width={width} height={height} className={colorClass} viewBox={view_box} xmlns="http://www.w3.org/2000/svg">
        <Icon name={name} />
      </svg>
    </div>
  );
};

export default MBDynamicIcon;
