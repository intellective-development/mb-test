import template from 'legacy_store/templates/store/checkout_choose_payment_profile';
import { BackboneRXView } from '../../shared/utils/backbone_rx';

/*jshint -W020 */
const CheckoutChoosePaymentProfileView = BackboneRXView.extend({
  el: '#checkout-detail',
  template: template,
  events: {
    'click #button-cancel-payment-profile' : 'cancelHandler',
    'click li.credit_card'                 : 'selectHandler'
  },
  initialize: function(){
    this.listenTo(User, 'user:payment_profile:error', this.handleSubmissionErrors);
    Store.CheckoutPaymentProfile = this;
    this.trackScreen('checkout_payment');
    this.render();
  },
  render: function(){
    this.$el.html(this.template({
      payment_profiles: User.get('payment_profiles')
    }));

    return this;
  },
  selectHandler: function(e){
    var id = $(e.target).closest('.credit_card').data('id');
    if(id){
      Store.Order.set('payment_profile_id', id);
      Store.CheckoutView.trigger('payment_profile:select');
    } else {
      Raven.captureMessage('No Payment Profile ID');
    }

    return false;
  },
  cancelHandler: function(){
    this.stopListening();
    Store.CheckoutView.trigger('payment_profile:cancel');
    return false;
  },
});

export default CheckoutChoosePaymentProfileView;

//TODO: remove! use real dependencies!
window.CheckoutChoosePaymentProfileView = CheckoutChoosePaymentProfileView;
