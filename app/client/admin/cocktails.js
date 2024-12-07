import React from 'react';
import { Provider } from 'react-redux';
import { Route, BrowserRouter as Router } from 'react-router-dom';
import store from './admin_store';
import CocktailsApp from './cocktails/';

export default () => (
  <Provider store={store}>
    <Router>
      <Route path="/admin/cocktails" component={CocktailsApp} />
    </Router>
  </Provider>
);
