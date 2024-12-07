// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import I18n from 'store/localization';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { MBModal, MBText, MBLayout, MBButton } from 'store/views/elements';
import type { Supplier } from 'store/business/supplier';
import DeliveryMethodIcon from 'store/views/compounds/DeliveryMethodIcon';
import type { DeliveryMethod } from 'store/business/delivery_method';
import { supplier_selectors } from 'store/business/supplier';

type OwnProps = {
  addToCart: () => void,
  productGrouping: { tags: string[] },
  variant: { supplier_id: number }
};

type StateProps = {
  supplier?: Supplier,
  delivery_method?: DeliveryMethod,
  is_shipped: boolean
};

type State = {
  show_warning: boolean
};

type EventHandler = (e: Event) => void;

const WithShippingWarningSTP = () => {
  const findSupplier = Ent.find('supplier');
  const findDeliveryMethod = Ent.find('delivery_method');

  return (state, { variant: { supplier_id } }: OwnProps): StateProps => {
    const supplier = findSupplier(state, supplier_id);
    const delivery_method = findDeliveryMethod(state, supplier_selectors.supplierSelectedDeliveryMethod(state, supplier_id));
    const is_shipped = delivery_method && delivery_method.type === 'shipped';

    return { is_shipped, supplier };
  };
};

export const addShippingWarning = (Component: React.ComponentType<OwnProps>) => {
  class WithShippingWarning extends React.Component<OwnProps & StateProps, State> {
    state = { show_warning: false }
    showWarning = () => { this.setState(() => ({ show_warning: true })); }
    hideWarning = (e: Event, onHide?: EventHandler) => {
      this.setState(() => ({ show_warning: false }));
      if (onHide) onHide(e);
    }
    hideWarningWithCallback = (onHide: EventHandler) => (e: Event) => this.hideWarning(e, onHide)
    isVineyardSelect = () => (this.props.supplier && this.props.supplier.type === 'Vineyard Select')
    render(){
      if (!this.props.is_shipped) return <Component {...this.props} />;

      const { show_warning } = this.state;
      const { addToCart, supplier, ...otherProps } = this.props;

      return (
        <React.Fragment>
          <ShippingWarning
            show={show_warning}
            confirm={this.hideWarningWithCallback(addToCart)}
            is_vineyard_select={this.isVineyardSelect()}
            deny={this.hideWarning}
            supplier={supplier} />
          <Component {...otherProps} addToCart={this.showWarning} />
        </React.Fragment>
      );
    }
  }

  return connect(WithShippingWarningSTP)(WithShippingWarning);
};

const ShippingWarning = ({ confirm, deny, show, supplier, is_vineyard_select }) => (
  <MBModal.Modal
    show={show}
    onHide={deny}
    size="small">
    <MBModal.SectionHeader renderRight={() => <MBModal.Close onClick={deny} />} />
    <div className="modal-container center">
      <div className="cm-shipping-warning-text-container">
        <MBText.P className="cm-shipping-warning-title">
          {I18n.t('ui.shipping_warning_modal.header')}
        </MBText.P>
        <br />
        <MBText.P>
          {is_vineyard_select
            ? I18n.t('ui.shipping_warning_modal.body_vineyard_select')
            : I18n.t('ui.shipping_warning_modal.body_default', { supplier_name: supplier.name })
          }
        </MBText.P>
        <div className="cm-shipping-warning-shipping-info">
          <DeliveryMethodIcon className="cm-shipping-warning-shipping-info__icon" delivery_method_type="shipped" />
          <MBText.P className="cm-shipping-warning-shipping-info__text" body_copy>
            {I18n.t('ui.shipping_warning_modal.shipping_time_estimate')}
          </MBText.P>
        </div>
      </div>
      <MBLayout.ButtonGroup className="action-container">
        <MBButton
          type="hollow"
          size="tall"
          onClick={deny}
          expand>
          {I18n.t('ui.shipping_warning_modal.cancel')}
        </MBButton>
        <MBButton
          type="action"
          size="tall"
          onClick={confirm}
          expand>
          {I18n.t('ui.shipping_warning_modal.confirm')}
        </MBButton>
      </MBLayout.ButtonGroup>
    </div>
  </MBModal.Modal>
);

export default addShippingWarning;
