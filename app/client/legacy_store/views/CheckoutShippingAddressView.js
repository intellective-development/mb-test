import _ from 'lodash';
import template from 'legacy_store/templates/store/checkout_shipping_address';
import { address_selectors } from 'store/business/address';
import { BackboneRXView } from '../../shared/utils/backbone_rx';

/*jshint -W020 */
const CheckoutShippingAddressView = BackboneRXView.extend({
  el: '#checkout-detail',
  template: template,
  events: {
    'change .radio-address_type': 'changeAddressType',
    'click .change-address': 'changeAddress'
  },
  validationRules: {
    address_name: {
      required: true,
      maxlength: 255
    },
    address_address2: {
      required: false,
      maxlength: 255
    },
    address_phone: {
      required: true,
      phoneUS: true
    }
  },
  validationMessages: {
    address_phone: {
      required: 'Phone number is required.'
    }
  },
  initialize: function(){
    this.listenTo(User, 'user:shipping_address:error', this.handleSubmissionErrors);
    Store.CheckoutShippingAddress = this;
    this.trackScreen("checkout_address");
    this.render();
  },
  render: function(){
    this.$el.html(this.template({
      name: User.fullName(),
      shipping_address: Store.DeliveryAddress.toJSON(),
      delivery_notes: Store.Order.get('delivery_notes') || ''
    }));
    this.initializeValidation();

    return this;
  },
  initializeValidation: function(){
    $('#address_phone').payment('formatPhone');
    $('#checkout-confirm-delivery', this.el).validate({
      submitHandler:  this.submitHandler,
      errorPlacement: Validation.errorPlacement,
      highlight:      Validation.highlight,
      unhighlight:    Validation.unhighlight,
      rules:          this.validationRules,
      messages:       this.validationMessages
    });
  },
  disable: function(){
    $('.checkout-frame').removeClass('shake');
    this.$('button').addClass('disabled').html('Updating Address...').attr('disabled','disabled');
  },
  enable: function(){
    $('.checkout-frame').addClass('shake');
    this.$('button').removeClass('disabled').html('Continue').removeAttr('disabled');
  },
  changeAddressType: function(){
    var deliveryNotes = this.$('#address_delivery_notes');

    if(this.isBusinessAddress()){
      this.$('.show-for_residential').hide();
      this.$('.show-for_business').show();
      deliveryNotes.attr('placeholder', deliveryNotes.data('business_placeholder'));
    } else {
      this.$('.show-for_business').hide();
      this.$('.show-for_residential').show();
      this.clearCompanyField();
      deliveryNotes.attr('placeholder', deliveryNotes.data('residential_placeholder'));
    }
  },
  changeAddress: function(){
    MiniBarView.changeAddress();
  },
  isBusinessAddress: function(){
    return this.$('#address_type_business').is(':checked');
  },
  clearCompanyField: function(){
    $('#address_company').val('');
  },
  submitHandler: function(){
    Store.CheckoutShippingAddress.disable();

    Store.DeliveryAddress.set({
      name:     $('#address_name').val(),
      company:  $('#address_company').val(),
      address2: $('#address_address2').val(),
      phone:    $('#address_phone').val()
    }, { silent: true });

    const { id_copy: id, local_id } = Store.DeliveryAddress.attributes;

    const state = Store.DeliveryAddress.storeGetState();
    const addressFromStore = address_selectors.getAddressById(state)(local_id);

    const keysToCompare = Object.keys(_.omit(Store.DeliveryAddress.attributes, ['id', 'id_copy']));
    const isAddressNotChanged = _.isEqual(_.pick(addressFromStore, keysToCompare), _.pick(Store.DeliveryAddress.attributes, keysToCompare));

    if (isAddressNotChanged){
      Store.DeliveryAddress.set({ id });
      return Store.DeliveryAddress.handleAddressSaved();
    }

    if (Store.DeliveryAddress.isValid()){
      User.addShippingAddress(Store.DeliveryAddress.toPure());
      Store.Order.set('delivery_notes', $('#address_delivery_notes').val());
    } else {
      Store.CheckoutShippingAddress.handleSubmissionErrors(
        Store.DeliveryAddress.validationError
      );
    }
    return false;
  },
  handleSubmissionErrors: function(error_message){
    MiniBarView.scrollToTop();
    this.enable();
    this.$('p.error').show().text(error_message);
  }
});

export default CheckoutShippingAddressView;

//TODO: remove! use real dependencies!
window.CheckoutShippingAddressView = CheckoutShippingAddressView;
