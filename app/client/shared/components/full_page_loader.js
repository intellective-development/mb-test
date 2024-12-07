import * as React from 'react';
import classNames from 'classnames';

const FullPageLoader = ({hidden}) => {
  const loader_classes = classNames('full-page-loader', {hidden: hidden});
  return <div className={loader_classes} />;
};

export default FullPageLoader;
