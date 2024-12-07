import logInTpl from 'legacy_store/templates/store/checkout_login';
import logInErrorTpl from 'legacy_store/templates/store/checkout_login_error';
import { BackboneRXView } from '../../shared/utils/backbone_rx';

Store.LogInView = BackboneRXView.extend({
  el: '#checkout-detail',
  logInTpl: logInTpl,
  logInErrorTpl: logInErrorTpl,
  events: {
    'click #button-new-user'    :   'create',
  },
  tracked: false,
  initialize: function(){
    this.listenTo(User, 'login:error', this.handleLoginError);
  },
  create: function(){
    User.setNewUser(true);
    return false;
  },
  login: function(){
    var view = this;
      view.toggleButton();
      view.hideError();

    User.attemptLogin(this.$('#login-email').val(), this.$('#login-password').val());

    return false;
  },
  toggleButton: function(e){
    var $button = this.$('#button-log-in');

    if($button.hasClass('disabled')){
        $button.removeClass('disabled').text('Log In');
    } else {
      $button.addClass('disabled').text('Processing...');

      this.listenToOnce(this, 'login:complete', this.toggleButton);
    }
  },
  handleLoginError: function(){
    MiniBarView.scrollToTop();
    this.showError('There was a problem logging you in, please check your details and try again.');
    this.toggleButton();
  },
  showError: function(error){
    this.$('#checkout-login-form').addClass('shake');
    this.$('#form-login .errors').html(this.logInErrorTpl({
      error: error
    })).fadeIn();
  },
  hideError: function(){
    this.$('#checkout-login-form').removeClass('shake');
  },
  trackView: function(){
    // don't want to multi-track, and check that the checkout view has already actually come into view
    if (!this.tracked && Store.CheckoutView.tracked){
      this.trackScreen('checkout_login');
      this.tracked = true;
    }
  },
  render: function(){
    var view = this;
    view.$el.html(view.logInTpl());

    this.trackView();

    $('#form-login').validate({
      submitHandler: function(){
        view.login();
        return false;
      },
      errorElement: 'label',
      errorPlacement: Validation.errorPlacement,
      highlight: Validation.highlight,
      unhighlight: Validation.unhighlight
    });

    return this;
  }
});

export default Store.LogInView;

//TODO: remove! use real dependencies!
window.Store.LogInView = Store.LogInView;
