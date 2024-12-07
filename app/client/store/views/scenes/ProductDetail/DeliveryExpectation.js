// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import type { DeliveryMethod } from 'store/business/delivery_method';
import { supplier_selectors } from 'store/business/supplier';
import { delivery_method_helpers } from 'store/business/delivery_method';
import type { Supplier } from 'store/business/supplier';

import DeliveryMethodIcon from 'store/views/compounds/DeliveryMethodIcon';
import { hasShopRunnerToken } from 'shared/utils/shop_runner';

type DeliveryExpectationProps = { supplier: Supplier, delivery_method: DeliveryMethod };
const DeliveryExpectation = ({ supplier, delivery_method }: DeliveryExpectationProps) => {
  if (!supplier || !delivery_method) return null;

  let icon;
  if (hasShopRunnerToken()){
    icon = <div className="delivery-expectation__shoprunner-icon" name="sr_smallBannerDiv" />;
  } else {
    icon = <DeliveryMethodIcon delivery_method_type={delivery_method.type} className="delivery-expectation__icon" />;
  }

  return (
    <div className="delivery-expectation">
      {icon}
      <div className="delivery-expectation__container">
        <span className="delivery-expectation__name">{supplier.name}</span>
        <span className="delivery-expectation__next-delivery">
          <DeliveryExpectationClosed delivery_method={delivery_method} />
          {delivery_method_helpers.formatNextDelivery(delivery_method, { include_type: true })}
        </span>
        <div className="delivery-expectation__shoprunner-message" name="sr_productDetailDiv" />
      </div>
    </div>
  );
};

const DeliveryExpectationClosed = ({ delivery_method }) => {
  if (delivery_method_helpers.isClosed(delivery_method)){
    return (
      <span>
        <span className="delivery-expectation__open">Open.</span>
        {' - '}
      </span>
    );
  }

  return (
    <span>
      <span className="delivery-expectation__closed">Closed</span>
      {' - '}
    </span>
  );
};

const DeliveryExpectationSTP = () => {
  const findSupplier = Ent.find('supplier');
  const findDeliveryMethod = Ent.find('delivery_method');

  return (state, { supplier_id }) => {
    const supplier = findSupplier(state, supplier_id);

    // if the user changes addresses while on the PDP, this supplier will become undefined before the redirect.
    // TODO: rethink this once we've got more control over the routing
    if (!supplier) return {};

    const delivery_method_id = supplier_selectors.supplierSelectedDeliveryMethod(state, supplier.id);
    const delivery_method = findDeliveryMethod(state, delivery_method_id);

    return { supplier, delivery_method };
  };
};

const DeliveryExpectationContainer = connect(DeliveryExpectationSTP)(DeliveryExpectation);
export default DeliveryExpectationContainer;
