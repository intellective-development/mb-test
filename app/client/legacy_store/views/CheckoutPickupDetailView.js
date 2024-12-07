import _ from 'lodash';
import template from 'legacy_store/templates/store/checkout_pickup_detail';
import { BackboneRXView } from '../../shared/utils/backbone_rx';

const CheckoutPickupDetailView = BackboneRXView.extend({
  el: '#checkout-detail',
  template: template,
  events: {},
  validationRules: {
    pickup_detail_name: {
      required: true,
      maxlength: 255
    },
    pickup_detail_phone: {
      required: true,
      phoneUS: true
    }
  },
  validationMessages: {
    pickup_detail_name: {
      required: 'Name is required.'
    },
    pickup_detail_phone: {
      required: 'Phone number is required.'
    }
  },
  initialize: function(){
    this.listenTo(User, 'user:pickup_detail:error', this.handleSubmissionErrors);
    Store.CheckoutPickupDetail = this;
    this.trackScreen('checkout_pickup_detail');
    this.render();
  },
  render: function(){
    this.$el.html(this.template({
      name: User.fullName(),
      pickup_detail: Store.PickupDetail.toJSON()
    }));
    this.initializeValidation();

    return this;
  },
  initializeValidation: function(){
    $('#pickup_detail_phone').payment('formatPhone');
    this.$('#checkout-pickup-detail').validate({
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
    this.$('button').addClass('disabled').html('Updating...').attr('disabled', 'disabled');
  },
  enable: function(){
    $('.checkout-frame').addClass('shake');
    this.$('button').removeClass('disabled').html('Continue').removeAttr('disabled');
  },
  submitHandler: function(){
    Store.CheckoutPickupDetail.disable();

    Store.PickupDetail.set({
      name:     $('#pickup_detail_name').val(),
      phone:    $('#pickup_detail_phone').val()
    }, { silent: true });

    if (Store.PickupDetail.isValid()){
      User.addPickupDetail(Store.PickupDetail);
    } else {
      Store.CheckoutPickupDetail.handleSubmissionErrors({
        description: Store.PickupDetail.validationError
      });
    }
    return false;
  },
  handleSubmissionErrors: function(error){
    MiniBarView.scrollToTop();
    this.enable();
    var error_str = _.capitalize(error.name) + ' ' + error.description;
    this.$('p.error').show().text(error_str);
  }
});

export default CheckoutPickupDetailView;

//TODO: remove! use real dependencies!
window.CheckoutPickupDetailView = CheckoutPickupDetailView;
