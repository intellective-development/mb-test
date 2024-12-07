// @flow

import * as React from 'react';
import bindClassNames from '../../../shared/utils/bind_classnames';

import styles from './MBDrawer.scss';

/*
  This component defines the styles for a simple side drawer.
  Its state is intended to be controlled by some parent component, avoiding the need for something like a ref to control it.
*/

const cn = bindClassNames(styles);

type MBDrawerProps = { open: boolean, closeDrawer: () => void, children: React.Node };
const MBDrawer = ({open, closeDrawer, children}: MBDrawerProps) => {
  const drawer_classes = cn('elMBDrawer', {elMBDrawer__Hidden: !open});
  const overlay_classes = cn('elMBDrawer_Overlay', {elMBDrawer_Overlay__Hidden: !open});

  return (
    <div>
      <div className={overlay_classes} onClick={closeDrawer} />
      <div className={drawer_classes}>
        {children}
      </div>
    </div>
  );
};

export default MBDrawer;
