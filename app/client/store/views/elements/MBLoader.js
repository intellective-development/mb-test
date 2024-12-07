// @flow
import * as React from 'react';
import bindClassNames from '../../../shared/utils/bind_classnames';
import styles from './MBLoader.scss';

const cn = bindClassNames(styles);

type Props = {
  className?: string
}

const MBLoader = ({ className }: Props) => {
  return (
    <div className={className}>
      <div className={cn('MBLoader_Ball', 'MBLoader_Ball__1')} />
      <div className={cn('MBLoader_Ball', 'MBLoader_Ball__2')} />
      <div className={cn('MBLoader_Ball', 'MBLoader_Ball__3')} />
    </div>
  );
};

export default MBLoader;
