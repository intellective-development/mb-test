// @flow
// this one is processed in webpack.base.config.js

import React from 'react';
import ReactDOM from 'react-dom';
import 'shared/polyfills';

import './legacy_store/store';
import './store/data_store';
import apiAuthenticate from './shared/web_authentication';
import App from './app';
import { initLogrocket } from './logrocket';

apiAuthenticate();
initLogrocket();

ReactDOM.render(<App />, document.getElementById('root'));
