// @flow

import * as React from 'react';
import { delivery_method_helpers } from 'store/business/delivery_method';

import { MBText } from '../../../elements';

type DeliveryInfoProps = {shipment: Object};
class DeliveryInfo extends React.PureComponent<DeliveryInfoProps> {
  render(){
    const { delivery_method } = this.props.shipment;

    return (
      <div className="csl__delivery__container">
        <div className="csl__delivery__name-container">
          <MBText.Span className="csl__delivery__name">
            {delivery_method_helpers.displayName(delivery_method)}
            <ClosedWarning delivery_method={this.props.shipment.delivery_method} />
          </MBText.Span>
        </div>
        <MBText.Span className="csl__delivery__next-delivery">
          {delivery_method_helpers.formatNextDelivery(delivery_method)}
        </MBText.Span>
      </div>
    );
  }
}

const ClosedWarning = ({delivery_method}) => {
  if (!delivery_method_helpers.isClosed(delivery_method)) return null;

  return <MBText.Span className="csl__delivery__closed">&ensp;Closed</MBText.Span>;
};

export default DeliveryInfo;
