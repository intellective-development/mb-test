import * as React from 'react';
import renderComponentRoot from 'shared/utils/render_component_root';

import ShipmentListComponent from 'store/views/scenes/CheckoutConfirm/ShipmentList';

const renderCheckoutShipments = () => renderComponentRoot(
  React.createElement(ShipmentListComponent),
  document.getElementById('checkout-shipment')
);

Store.CheckoutShipmentView = Backbone.View.extend({
  el: '#checkout-shipment',
  render(){
    renderCheckoutShipments();
  }

  // leaving these in to reference when implementing checkout delivery method switching

  // events: {
  //   'change .delivery-method'            : 'deliveryMethodSelected',
  // },

  // setDeliveryMethod: function(delivery_method){
  //   this.delivery_method = delivery_method;
  // },
  // deliveryMethodSelected: function(e){
  //   var el = $(event.target),
  //       delivery_method_id = el.val(),
  //       delivery_method = this.supplier.get('delivery_methods').get(delivery_method_id);

  //   // set the delivery method on the order, update order
  //   Store.Order.updateOrderItems({
  //     'delivery_method_id': delivery_method_id,
  //     'scheduled'         : false,  // reset these in case they've been set
  //     'scheduled_for'     : null
  //   }, this.supplier_id);
  //   Store.Order.updateOrder();

  //   // hide the scheduling if shouldn't be allowed
  //   if (!delivery_method.get('allows_scheduling')){
  //     var scheduling_selection = this.$delivery_form.children('.scheduling-selection');
  //     scheduling_selection.fadeOut('fast');
  //   }

  //   // update the delivery method in the store, get the scheduling dates
  //   this.setDeliveryMethod(delivery_method);
  //   this.handleErrors();
  // }
});

// enable hot reloading
// if (module.hot) module.hot.accept('store/views/scenes/CheckoutConfirm/ShipmentList', renderCheckoutShipments);

export default Store.CheckoutShipmentView;

//TODO: remove! use real dependencies!
window.Store.CheckoutShipmentView = Store.CheckoutShipmentView;
