// @flow

import * as React from 'react';
import _ from 'lodash';
import bindClassNames from 'shared/utils/bind_classnames';
import type { DeliveryMethodType } from 'store/business/delivery_method';
import styles from './index.scss';

const cn = bindClassNames(styles);

type DeliveryMethodIconProps = {delivery_method_type: DeliveryMethodType, width: number, height: number, active?: boolean, className?: string}
const DeliveryMethodIcon = ({delivery_method_type, width, height, active, className}: DeliveryMethodIconProps) => {
  const icon_name = active ? `${delivery_method_type}__red` : delivery_method_type;

  return (
    <img
      alt={delivery_method_type}
      className={cn('cmDeliveryMethodIcon', className)}
      height={height}
      width={width}
      src={`/assets/components/compounds/delivery_method_icon/${icon_name}.svg`} />
  );
};

type MultiDeliveryMethodIconProps = {delivery_method_types: Array<DeliveryMethodType>, width: number, height: number, className?: string};
const MultiDeliveryMethodIcon = ({delivery_method_types, width, height, className}: MultiDeliveryMethodIconProps) => {
  // we uniq these and sort them alphabetically, as the ordering in the prop shouldn't matter
  const uniq_types = _.uniq(delivery_method_types);
  const icon_name = _.sortBy(uniq_types).join('__');

  return (
    <img
      alt={icon_name}
      className={cn('cmDeliveryMethodIcon_Multi', className)}
      height={height}
      width={width}
      src={`/assets/components/compounds/delivery_method_icon/${icon_name}.svg`} />
  );
};

export default DeliveryMethodIcon;
export { MultiDeliveryMethodIcon };
