import template from 'legacy_store/templates/store/checkout_user_profile';
import mailcheckWrapper from 'legacy_store/utils/mailcheck_wrapper';
import { BackboneRXView } from '../../shared/utils/backbone_rx';

const CheckoutNewUserView = BackboneRXView.extend({
  el: '#checkout-detail',
  events: {
    'click #button-login' : 'cancelHandler'
  },
  template: template,
  validationRules: {
    user_first_name: {
      required: true,
      maxlength: 35,
      minlength: 2,
      letterswithbasicpunc: true
    },
    user_last_name: {
      required: true,
      maxlength: 35,
      minlength: 2,
      letterswithbasicpunc: true
    },
    user_email: {
      required: true,
      maxlength: 255
    },
    user_password: {
      required: true,
      minlength: 6
    },
    user_confirm_password: {
      equalTo:  '#user_password',
      required: true,
      minlength: 6
    }
  },
  initialize: function(){
    this.listenTo(User, 'user:error', this.handleSubmissionErrors);
    Store.CheckoutNewUser = this;
    this.trackScreen("checkout_register");
    this.render();
  },
  render: function(){
    this.$el.html(this.template());
    this.initializeValidation();
    mailcheckWrapper.initialize($('#user_email'),$('#hint'),$('#full-suggestion'));
    return this;
  },
  initializeValidation: function(){
    $('#checkout-user-profile', this.el).validate({
      submitHandler:  this.submitHandler,
      errorPlacement: Validation.errorPlacement,
      highlight:      Validation.highlight,
      unhighlight:    Validation.unhighlight,
      rules:          this.validationRules
    });
  },
  disable: function(){
    $('.checkout-frame').removeClass('shake');
    this.$('#button-create-user').addClass('disabled').html('Processing...').attr('disabled','disabled');
    this.$('#button-login').addClass('disabled').attr('disabled','disabled');
  },
  enable: function(){
    $('.checkout-frame').addClass('shake');
    this.$('#button-create-user').removeClass('disabled').html('Continue').removeAttr('disabled');
    this.$('#button-login').removeClass('disabled').removeAttr('disabled');
  },
  cancelHandler: function(){
    User.setNewUser(false);
  },
  submitHandler: function(){
    Store.CheckoutNewUser.disable();

    const user_data = {
      first_name: $('#user_first_name').val(),
      last_name:  $('#user_last_name').val(),
      email:      $('#user_email').val(),
      password:   $('#user_password').val(),
      password_confirmation: $('#user_confirm_password').val()
    };

    var dataLayer = window.dataLayer || [];
    // dataLayer.push({'Referral Code': User.get('referral_code')}); // TODO: did this work?
    dataLayer.push({'event': 'registration'});
    User.signUp(user_data);
    return false;
  },
  handleSubmissionErrors: function(error_message){
    $('.checkout-frame').addClass('shake');

    MiniBarView.scrollToTop();
    this.enable();
    this.$('p.error').show().text(error_message);
  }
});

export default CheckoutNewUserView;

//TODO: remove! use real dependencies!
window.CheckoutNewUserView = CheckoutNewUserView;
