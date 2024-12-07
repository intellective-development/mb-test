import { FORM_ERROR } from 'final-form';

export const handleSubmitWithCaptcha = (next, action) => async(form) => {
  try {
    if (!window.grecaptcha){
      return;
    }
    const token = await window.grecaptcha.execute(window.recaptcha_v3_site_key, { action });
    // eslint-disable-next-line no-param-reassign
    form.recaptcha_v3_token = token;
    await next(form, true);
  } catch ({error, message}){
    return ({[FORM_ERROR]: error || `reCAPTCHA error: ${message}`});
  }
};

export const addGoogleReCaptchaScript = () => {
  const id = 'google-recaptcha-v3-id';
  if (document.getElementById(id)){
    return;
  }
  const js = document.createElement('script');
  js.setAttribute('id', id);
  js.src = `https://www.google.com/recaptcha/api.js?render=${window.recaptcha_v3_site_key}`;
  document.getElementsByTagName('head')[0].appendChild(js);
};
