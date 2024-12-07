// @flow

type Placement = {id: string, impression_tracking_url: string, click_tracking_url: string};

// TODO:  Implement endpoint for tracking content placement clicks and impressions.
//        We should also think about what (if anything) gets sent to Google Analytics
//        and Tag Manager (probably the internal name of the content).


export const trackPlacementClick = (_placement: Placement) => {
  // trackEvent(placement.click_tracking_url);
};

export const trackPlacementImpression = (_placement: Placement) => {
  // trackEvent(placement.impression_tracking_url);
};

const _trackEvent = (tracking_url?: string) => {
  if (tracking_url){
    const dataLayer = window.dataLayer || [];
    dataLayer.push({ event: tracking_url });
  }
};
