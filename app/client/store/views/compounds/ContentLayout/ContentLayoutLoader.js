import * as React from 'react';
import bindClassNames from 'shared/utils/bind_classnames';
import styles from './ContentLayout.scss';

const cn = bindClassNames(styles);

export const ContentLayoutLoader = () => (
  <div className={cn('cmContentLayout__Loading')} />
);
