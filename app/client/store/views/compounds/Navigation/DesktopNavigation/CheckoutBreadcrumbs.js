// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import bindClassNames from 'shared/utils/bind_classnames';
import * as Ent from '@minibar/store-business/src/utils/ent';
import connectToObservables from 'shared/components/higher_order/connect_observables';
import * as shipment_helpers from 'legacy_store/models/Shipment';
import { orderStream } from 'legacy_store/models/Order';
import { order_helpers } from 'store/business/order';
import { cart_item_selectors } from 'store/business/cart_item';
import { supplier_selectors } from 'store/business/supplier';

import { MBButton, MBIcon, MBText } from '../../../elements';
import styles from './CheckoutBreadcrumbs.scss';

const cn = bindClassNames(styles);

type Step = 'sign-in' | 'delivery' | 'payment' | 'checkout' | 'hidden';
const STEPS: Step[] = ['sign-in', 'delivery', 'payment', 'checkout'];
const COMPLETED_STEP: Step = 'hidden';

type CheckoutBreadcrumbsProps = {contact_label_copy: string};
type CheckoutBreadcrumbsState = {current_step: Step};

class CheckoutBreadcrumbs extends React.Component<CheckoutBreadcrumbsProps, CheckoutBreadcrumbsState> {
  state = {current_step: 'sign-in'};

  constructor(props: CheckoutBreadcrumbsProps){
    super(props);

    if (typeof Store === 'undefined') return undefined;
    this.state = {current_step: window.Store.CheckoutView.viewState()};
  }

  componentDidMount(){
    if (typeof Store === 'undefined') return undefined;

    window.Store.CheckoutView.on('checkout_breadcrumb:view_state', () => {
      this.setState({current_step: window.Store.CheckoutView.viewState()});
    }, this);
  }

  componentWillUnmount(){
    if (typeof Store === 'undefined') return undefined;

    window.Store.CheckoutView.off(null, null, this);
  }

  stepState = (step: Step) => {
    const { current_step } = this.state;
    if (step === current_step){
      return 'current';
    } else if (STEPS.indexOf(step) < STEPS.indexOf(current_step)){
      return 'completed';
    } else {
      return 'pending';
    }
  }

  render(){
    const { contact_label_copy } = this.props;
    const { current_step } = this.state;

    if (current_step === COMPLETED_STEP) return <CompletedContent />;

    return (
      <div className={styles.cmCheckoutBreadcrumbs_Wrapper}>
        <div className={styles.cmCheckoutBreadcrumbs_ContentContainer}>
          <div className={styles.cmCheckoutBreadcrumbs_BarContainer}>
            <div className={cn('cmCheckoutBreadcrumbs_Bar', `cmCheckoutBreadcrumbs_Bar__${current_step}`)} />
          </div>
          <div className={styles.cmCheckoutBreadcrumbs_StepContainer}>
            <StepElement state={this.stepState('sign-in')}>Account</StepElement>
            <StepElement state={this.stepState('delivery')}>{contact_label_copy}</StepElement>
            <StepElement state={this.stepState('payment')}>Payment</StepElement>
            <StepElement state={this.stepState('checkout')}>Review Order</StepElement>
          </div>
        </div>
      </div>
    );
  }
}

type StepElementProps = {state: 'current' | 'completed' | 'pending', children: React.Node}
const StepElement = ({state, children}: StepElementProps) => {
  const step_classes = cn('cmCheckoutBreadcrumbs_Step', {
    cmCheckoutBreadcrumbs_Step__Current: state === 'completed',
    cmCheckoutBreadcrumbs_Step__Completed: state === 'current'
  });

  return (
    <div className={step_classes}>
      <div className={styles.cmCheckoutBreadcrumbs_Step_Pip}>
        <MBIcon name="check" className={styles.cmCheckoutBreadcrumbs_CompletedIcon} />
      </div>
      <MBText.Span>{children}</MBText.Span>
    </div>
  );
};

const CompletedContent = () => {
  return (
    <a
      href="/store/"
      className={styles.cmCheckoutBreadcrumbs_CompletedWrapper}>
      <MBButton type="hollow" size="small">Shop More ▸</MBButton>
    </a>
  );
};

const CheckoutBreadcrumbsSTP = () => {
  const findCartItems = Ent.query(Ent.find('cart_item'), Ent.join('variant'), Ent.join('product_grouping'));
  const findSuppliers = Ent.query(Ent.find('supplier'), Ent.join('delivery_methods'));
  return (state, {order}) => {
    if (!order) return {contact_label_copy: contactLabelCopy([])};
    const cart_items = findCartItems(state, cart_item_selectors.getAllCartItemIds(state));
    const suppliers = findSuppliers(state, supplier_selectors.currentSupplierIds(state));
    const selected_delivery_methods = supplier_selectors.selectedDeliveryMethods(state);
    const shipments = order_helpers.getOrderShipments(order, cart_items, suppliers, selected_delivery_methods);
    return {contact_label_copy: contactLabelCopy(shipments)};
  };
};
const CheckoutBreadcrumbsContainer = connect(CheckoutBreadcrumbsSTP)(CheckoutBreadcrumbs);

export default connectToObservables(CheckoutBreadcrumbsContainer, {order: orderStream});

// helpers

const contactLabelCopy = (shipments = []) => {
  const has_address = shipment_helpers.hasAddressShipments(shipments);
  const has_pickup = shipment_helpers.hasPickupShipments(shipments);

  let contact_label;
  if (has_address && has_pickup){
    contact_label = 'Contact';
  } else if (has_pickup){
    contact_label = 'Pickup';
  } else {
    contact_label = 'Address';
  }
  return contact_label;
};
