import config from '../session/config';

const gtag = window.gtag;

/* Page Tracking */
export const transformPageTrackingLocation = (location) => {
  switch (location.page_type){
    case 'home':
      return 'store';
    case 'product_list':
      return `/store/${location.fragment}`;
    case 'product_detail':
      return `/store/product/${location.params.permalink}`; // strips out the variant permalink, track grouping as a unit
    default:
      return `/store/${location.fragment}`;
  }
};

export const trackPageView = (tracking_location) => {
  // Send to GTM
  const dataLayer = window.dataLayer || [];
  dataLayer.push({
    event: 'VirtualPageView',
    virtualPageURL: tracking_location
  });

  // Send to SiftScience
  const _sift = window._sift || [];
  _sift.push(['_trackPageview']);

  gtag('config', config.google_analytics_id, {
    page_path: tracking_location
  });
};

/* Checkout Tracking */
const checkout_step_numbers = {
  initiate: 1,
  authentication: 2,
  confirm_address: 3,
  add_payment: 4,
  confirmation: 5,
  thank_you: 6
};

export const trackCheckoutStep = function(action){
  const faux_location = `/store/checkout/${action.step_name}`;
  const step_number = checkout_step_numbers[String(action.step_name)];

  if (action.option === ''){
    gtag('event', 'set_checkout_option', {
      checkout_step: step_number
    });
  } else {
    gtag('event', 'set_checkout_option', {
      checkout_step: step_number,
      checkout_option: action.option
    });
  }

  trackPageView(faux_location); // important that this comes second
};
