// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import cn from 'classnames';
import I18n from 'store/localization';
import { delivery_method_helpers } from 'store/business/delivery_method';
import type { DeliveryMethod } from 'store/business/delivery_method';
import * as shipment_helpers from 'legacy_store/models/Shipment';
import { supplier_actions } from 'store/business/supplier';
import { hasShopRunnerToken, refreshShopRunnerContent } from 'shared/utils/shop_runner';

import formatCurrency from 'shared/utils/format_currency';
import { MBRadio, MBText, MBTouchable } from 'store/views/elements';

type DeliverySummaryProps = {shipment: Object, delivery_method: DeliveryMethod, selected: boolean, is_changeable: boolean, selectDeliveryMethod: Function};

class DeliverySummary extends React.PureComponent<DeliverySummaryProps> {
  componentDidMount(){
    refreshShopRunnerContent();
  }
  render(){
    const display_names_classes = cn('sp__dm__type', {'sp__dm__type--selected': this.props.selected});
    const display_name = (<MBText.Span className={display_names_classes}>{delivery_method_helpers.displayName(this.props.delivery_method)}</MBText.Span>);

    return (
      <MBTouchable
        className="sp__dm__container"
        disabled={!this.props.is_changeable}
        onClick={() => this.props.selectDeliveryMethod(this.props.shipment.supplier.id, this.props.delivery_method.id)} >
        <MBRadio active={this.props.selected} className="sp__dm__radio" />
        <div className="sp__dm__name-expectation-container">
          {display_name}
          <DeliveryMethodExpectation delivery_method={this.props.delivery_method} />
        </div>
        <DeliveryMethodCost delivery_method={this.props.delivery_method} shipment={this.props.shipment} />
      </MBTouchable>
    );
  }
}
const DeliverySummaryDTP = {selectDeliveryMethod: supplier_actions.selectDeliveryMethod};
const DeliverySummaryContainer = connect(null, DeliverySummaryDTP)(DeliverySummary);

const DeliveryMethodExpectation = ({delivery_method}) => {
  return (
    <MBText.Span className="sp__dm__next_delivery">
      <DeliveryExpectationClosed delivery_method={delivery_method} />
      {delivery_method_helpers.formatNextDelivery(delivery_method)}
    </MBText.Span>
  );
};

const DeliveryExpectationClosed = ({delivery_method}) => {
  if (!delivery_method_helpers.isClosed(delivery_method)) return null;

  return (
    <span>
      <span className="sp__dm__closed">Closed</span>
      {' - '}
    </span>
  );
};

const DeliveryMethodCost = ({delivery_method, shipment}) => {
  if (hasShopRunnerToken() && delivery_method.type !== 'pickup'){
    return (
      <div style={{ display: 'flex', flexGrow: 1, textAlign: 'right', minWidth: '200px' }}>
        <div style={{ width: '100%' }}>
          <div className={'_SRD'} style={{ display: 'inline-block', verticalAlign: 'middle', marginRight: '0.5em' }}>
            <div className={'srd_iconline'}>
              <div className="srd_logo" />
            </div>
          </div>
          Free delivery
        </div>
      </div>
    );
  }

  const subtotal = shipment_helpers.shipmentSubtotal(shipment);

  if (delivery_method_helpers.belowMinimum(delivery_method, subtotal)){
    return <DeliveryMethodMinimum delivery_method={delivery_method} />;
  } else {
    return <DeliveryMethodFee delivery_method={delivery_method} subtotal={subtotal} />;
  }
};

const DeliveryMethodMinimum = ({delivery_method}) => {
  return (
    <MBText.Span className="sp__dm__cost sp__dm__cost--minimum">
      {I18n.t('ui.body.cart.delivery_minimum_amount', {
        delivery_minimum: formatCurrency(delivery_method.delivery_minimum, {truncate: true})
      })}
    </MBText.Span>
  );
};

const DeliveryMethodFee = ({delivery_method, subtotal}) => {
  const delivery_fee = delivery_method_helpers.feeForSubtotal(delivery_method, subtotal);

  let formatted_delivery_fee;

  if (hasShopRunnerToken()){
    formatted_delivery_fee = I18n.t('ui.body.cart.shop_runner_delivery_fee');
  } else {
    formatted_delivery_fee = formatCurrency(delivery_fee, {truncate: true, use_free: true});
    if (delivery_fee > 0) formatted_delivery_fee = I18n.t('ui.body.cart.delivery_fee', {delivery_fee: formatted_delivery_fee});
  }

  return (
    <MBText.Span className="sp__dm__cost sp__dm__cost--fee">
      {formatted_delivery_fee}
    </MBText.Span>
  );
};

export default DeliverySummaryContainer;
