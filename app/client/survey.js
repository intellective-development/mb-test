// @flow

import 'shared/polyfills';
import * as React from 'react';
import renderComponentRoot from './shared/utils/render_component_root';

import App from './survey/app';

const SURVEY = window.survey;
const REFERRAL_CODE = window.referral_code;

const renderApp = () => {
  const container = document.getElementById('survey-root');
  if (container){
    renderComponentRoot(React.createElement(App, {survey: SURVEY, referralCode: REFERRAL_CODE}), container);
  }
};

// spin up app
$(document).ready(() => {
  renderApp();
});

// enable hot reloading
if (module.hot) module.hot.accept('./survey/app', renderApp);
