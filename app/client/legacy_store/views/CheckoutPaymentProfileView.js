import template from 'legacy_store/templates/store/checkout_payment_profile';
import { BackboneRXView } from '../../shared/utils/backbone_rx';
import BrainTree from '../../store/business/payment_profile/braintree';

/*jshint -W020 */
const CheckoutPaymentProfileView = BackboneRXView.extend({
  el: '#checkout-detail',
  template: template,
  events: {
    'change #checkbox-same-as-shipping' : 'onShippingCheckboxChanged',
    'keyup #billing_cc_number' : 'identifyCard',
    'click #button-cancel-payment-profile' : 'cancelHandler'
  },
  validationRules: {
    billing_name: {
      required: true,
      maxlength: 255
    },
    billing_address1: {
      required: true,
      maxlength: 255
    },
    billing_address2: {
      required: false,
      maxlength: 255
    },
    billing_city: {
      required: true
    },
    billing_state: {
      required: true,
      maxlength: 2
    },
    billing_zip_code: {
      required: 2,
      digits: true,
      minlength: 5,
      maxlength: 5
    }
  },
  validationMessages: {
    billing_cc_number: {
      required: 'Card number is required.'
    },
    billing_cc_exp: {
      required: 'Expiration date is required.'
    },
    billing_cc_cvc: {
      required: 'Security code is required.'
    }
  },
  initialize: function(){
    this.listenTo(User, 'user:payment_profile:error', this.handleSubmissionErrors);
    this.trackScreen("checkout_add_payment");
    Store.CheckoutPaymentProfile = this;
    this.render();
  },
  render: function(){
    var templateData = {
      shipping_address_info: $('#checkbox-same-as-shipping').is(':checked'),
      name: User.fullName(),
      shipping_address: Store.DeliveryAddress.toJSON(),
      allow_cancellation: Store.Order.get('payment_profile_id') === undefined ? false : true
    }
    this.$el.html(this.template(templateData));
    this.initializeValidation();
    BrainTree.renderFields();
    return this;
  },
  onShippingCheckboxChanged: function(){
    const isSame = $('#checkbox-same-as-shipping').is(':checked');
    this.fillFormData(isSame ? Store.DeliveryAddress.toJSON() : {});
  },
  fillFormData: function({ address1, address2, city, state, zip_code }){
    $("#billing_address1").val(address1);
    $("#billing_address2").val(address2);
    $("#billing_city").val(city);
    $("#billing_state").val(state);
    $("#billing_zip_code").val(zip_code);
  },
  initializeValidation: function(){
    $('#checkout-add-payment', this.el).validate({
      submitHandler:  this.submitHandler,
      errorPlacement: Validation.errorPlacement,
      highlight:      Validation.highlight,
      unhighlight:    Validation.unhighlight,
      rules:          this.validationRules,
      messages:       this.validationMessages
    });

    $('#billing_cc_number').payment('formatCardNumber');
    $('#billing_cc_exp').payment('formatCardExpiry');
    $('#billing_cc_cvc').payment('formatCardCVC');
  },
  identifyCard: function(){
    var cardType = $.payment.cardType($('#billing_cc_number').val()) || 'unknown';
    $('.cc-number .icon').attr('class','').addClass('icon').addClass(cardType);
  },
  disable: function(){
    $('.checkout-frame').removeClass('shake');
    this.$('#button-add-payment-profile').addClass('disabled').html('Processing...').attr('disabled','disabled');
    this.$('#button-cancel-payment-profile').addClass('disabled').attr('disabled','disabled');
  },
  enable: function(){
    $('.checkout-frame').addClass('shake');
    this.$('#button-add-payment-profile').removeClass('disabled').html('Continue').removeAttr('disabled');
    this.$('#button-cancel-payment-profile').removeClass('disabled').removeAttr('disabled');
  },
  submitHandler: function(){
    Store.CheckoutPaymentProfile.disable();
    var cardType = $.payment.cardType($('#billing-cc_num').val());

    $('#billing_cc_num').toggleClass('error', !$.payment.validateCardNumber($('#billing_cc_num').val()));
    $('#billing_cc_exp').toggleClass('error', !$.payment.validateCardExpiry($('#billing_cc_exp').payment('cardExpiryVal')));
    $('#billing_cc_cvc').toggleClass('error', !$.payment.validateCardCVC($('#billing_cc_cvc').val(), cardType));

    if ($('#checkout-add-payment input.error').length < 1){
      const profile = {
        cc_number:        $('#billing_cc_number').val(),
        name:             $('#billing_cc_name').val(),
        cc_expiry_month:  $('#billing_cc_exp').payment('cardExpiryVal').month,
        cc_expiry_year:   $('#billing_cc_exp').payment('cardExpiryVal').year,
        cvv:              $('#billing_cc_cvc').val(),
        // billing_default:  true,
        address: {
          name:       $('#billing_cc_name').val(),
          address1:   $('#billing_address1').val(),
          address2:   $('#billing_address2').val(),
          city:       $('#billing_city').val(),
          state:      $('#billing_state').val(),
          zip_code:   $('#billing_zip_code').val()
        }
      };
      User.addPaymentProfile(profile);
    } else {
      Store.CheckoutPaymentProfile.handleSubmissionErrors('Invalid Credit Card');
    }
    return false;
  },
  cancelHandler: function(){
    this.stopListening();
    Store.CheckoutView.trigger('payment_profile:cancel');
    return false;
  },
  handleBraintreeToken: function(err, nonce){

  },
  handleSubmissionErrors: function(error_message){
    $('#billing_cc_number').val('');
    $('#billing_cc_cvc').val('');
    $('#billing_cc_exp').val('');

    MiniBarView.scrollToTop();
    this.enable();
    this.$('p.error').show().text(error_message);
  }
});

export default CheckoutPaymentProfileView;

//TODO: remove! use real dependencies!
window.CheckoutPaymentProfileView = CheckoutPaymentProfileView;
