// @flow

import 'shared/polyfills';
import * as React from 'react';
import ReactDOM from 'react-dom';

import AuthorizationFlow from './oauth/main';

$(() => {
  ReactDOM.render(<AuthorizationFlow />, document.getElementById('authorization-form'));
});
