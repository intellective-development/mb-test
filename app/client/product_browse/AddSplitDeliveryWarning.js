// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import I18n from 'store/localization';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { MBModal, MBText, MBLayout, MBButton } from 'store/views/elements';
import type { Supplier } from 'store/business/supplier';
import { cart_item_helpers } from 'store/business/cart_item';
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

const SplitDeliveryWarningSTP = () => {
  const findSupplier = Ent.find('supplier');
  const findDeliveryMethod = Ent.find('delivery_method');

  return (state, { variant: { supplier_id } }: OwnProps): StateProps => {
    const supplier = findSupplier(state, supplier_id);
    const delivery_method = findDeliveryMethod(state, supplier_selectors.supplierSelectedDeliveryMethod(state, supplier_id));
    const is_shipped = delivery_method && delivery_method.type === 'shipped';

    return { is_shipped, supplier };
  };
};

export const addSplitDeliveryWarning = (Component: React.ComponentType<OwnProps>) => {
  class WithSplitDeliveryWarning extends React.Component<OwnProps & StateProps, State> {
    state = { show_warning: false, resolve: null, reject: null }
    showWarning = () => new Promise((resolve, reject) => { this.setState(() => ({ show_warning: true, resolve, reject })); });
    hideWarning = (e: Event, onHide?: EventHandler) => {
      const { resolve, reject } = this.state;
      this.setState(() => ({ show_warning: false }));
      if (onHide){
        resolve(onHide(e));
      } else {
        reject();
      }
    }
    hideWarningWithCallback = (onHide: EventHandler) => (e: Event) => this.hideWarning(e, onHide)
    render(){
      const { addToCart, supplier, cart_items, ...otherProps } = this.props;
      const items = cart_item_helpers.groupItemsBySupplier(cart_items);
      const supplier_in_cart = _.reduce(items[supplier.id], (sum, { quantity }) => sum + quantity, 0) > 0;

      if (cart_items.length === 0 || supplier_in_cart) return <Component {...this.props} />;

      const { show_warning } = this.state;

      return (
        <React.Fragment>
          <SplitDeliveryWarning
            show={show_warning}
            confirm={this.hideWarningWithCallback(addToCart)}
            deny={this.hideWarning}
            supplier={supplier} />
          <Component supplier={supplier} {...otherProps} addToCart={this.showWarning} />
        </React.Fragment>
      );
    }
  }

  return connect(SplitDeliveryWarningSTP)(WithSplitDeliveryWarning);
};

const SplitDeliveryWarning = ({ confirm, deny, show }) => (
  <MBModal.Modal
    show={show}
    onHide={deny}
    size="small">
    <MBModal.SectionHeader renderRight={() => <MBModal.Close onClick={deny} />} />
    <div className="modal-container center">
      <div className="cm-shipping-warning-text-container">
        <MBText.P className="cm-shipping-warning-title">
          {I18n.t('ui.split_warning_modal.header')}
        </MBText.P>
        <br />
        <MBText.P>
          {I18n.t('ui.split_warning_modal.body_default')}
        </MBText.P>
      </div>
      <MBLayout.ButtonGroup className="action-container">
        <MBButton
          type="hollow"
          size="tall"
          onClick={deny}
          expand>
          {I18n.t('ui.split_warning_modal.cancel')}
        </MBButton>
        <MBButton
          type="action"
          size="tall"
          onClick={confirm}
          expand>
          {I18n.t('ui.split_warning_modal.confirm')}
        </MBButton>
      </MBLayout.ButtonGroup>
    </div>
  </MBModal.Modal>
);

export default addSplitDeliveryWarning;
