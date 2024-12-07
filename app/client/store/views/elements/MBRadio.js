// @flow

import * as React from 'react';
import cn from 'classnames';

type MBRadioProps = {active: boolean, className?: string};
const MBRadio = ({active, className}: MBRadioProps) => {
  return (
    <div className={cn('el-radio__circle-outer', {'el-radio__circle-outer--active': active}, className)}>
      <div className={cn('el-radio__circle-inner', {'el-radio__circle-inner--active': active})} />
    </div>
  );
};

export default MBRadio;
