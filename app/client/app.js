import React, { useEffect } from 'react';
import _ from 'lodash';
/* TODO: will be replaced when moving to Next.js */
import { ConnectedRouter } from 'connected-react-router';
import { withRouter, Switch, Route, Redirect } from 'react-router-dom';
import { PersistGate } from 'redux-persist/integration/react';
/* *** */

import { Provider } from 'react-redux';
import store, { persistor } from './store/data_store';
import history from './shared/utils/history';
import qs from './utils/qs';

import Navigation from './store/views/compounds/Navigation';
import DeliveryInfoModal from './store/views/scenes/DeliveryInfoModal';

import GenericContentLayoutComponent from './store/views/scenes/GenericContentLayout';
import CartComponent from './cart/main';
import ProductDetailComponent from './store/views/scenes/ProductDetail';
import ProductListComponent from './store/views/scenes/ProductList';
import CartShareComponent from './store/views/scenes/CartShare';
import CheckoutComponent from './store/business/checkout';

import EmailCaptureModal from './store/views/compounds/EmailCaptureModal';
import PopupModal from './store/views/compounds/PopupMessage';
import {
  AppInstall as LandingAppInstall,
  EmailCapture as LandingEmailCapture,
  LandingHero
} from './store/views/scenes/LandingPage';

import Cocktails from '../client/cocktails';
import ThankYou from './store/business/checkout/ThankYou';
import ModalQueue from './ModalQueue';

const ScrollToTopOnLocationChangeContainer = ({ location, children }) => {
  useEffect(() => window.scrollTo(0, 0), [location]);
  return children;
};

export const ScrollToTop = withRouter(ScrollToTopOnLocationChangeContainer);

const getWebLayout = (content_layout_name) => `Web_${content_layout_name.split('-').map(_.startCase).join('_')}_Content_Screen`;

const renderPLP = ({ identifier, location, ...filter }) => {
  const { sort, ...param_filter } = qs.parse(location.search, { ignoreQueryPrefix: true });
  return (
    <ProductListComponent
      location={{
        identifier,
        filter: {
          ...filter,
          ...param_filter
        },
        sort
      }} />
  );
};

const RedirectCategories = ({ location, match: { params: { category, type, subtype } } }) => {
  const normalizedLocation = `/store/category/${category}`;
  const searchObject = qs.parse(location.search, { ignoreQueryPrefix: true });
  searchObject.hierarchy_type = [...(searchObject.hierarchy_type || []), type];
  searchObject.hierarchy_subtype = [...(searchObject.hierarchy_subtype || []), subtype];
  const newSearchObject = qs.stringify(searchObject, { encode: false, arrayFormat: 'brackets' });
  return <Redirect to={`${normalizedLocation}?${newSearchObject}`} />;
};

const Main = () => {
  return (
    <ScrollToTop>
      {/* TODO: how to wrap navigation for Next.js? */}
      <Switch>
        <Route
          path="/"
          exact
          render={() => {
            return (
              <React.Fragment>
                <LandingHero />
                {/*<Navigation />*/}
                {/*<StoreEntry />*/}
                <LandingAppInstall />
                <LandingEmailCapture />
                <EmailCaptureModal />
                {/*<PressPage />*/}
                {/*<ProductScroller />*/}
                {/*<PernodRicardWinter />*/}
                {/*<AddressExplanation />*/}
              </React.Fragment>
            );
          }} />
        <Route path="/store/checkout" render={() => <DeliveryInfoModal />} />
        <Route render={() => (
          <React.Fragment>
            {/*<EmailCaptureModal />*/} {/* https://minibar.atlassian.net/browse/TECH-1897 */}
            <PopupModal />
            <Navigation />
          </React.Fragment>
        )} />
      </Switch>
      {/* routes to be replaced by pages */}
      <Switch>
        <Route path="/store/checkout/:number/success" component={ThankYou} />
        <Route path="/store/checkout" component={CheckoutComponent} />
        <Route path="/store/cart" render={() => <CartComponent />} />
        <Route
          path="/store/product/:permalink/:variant_permalink?"
          render={({ match: { params: { permalink, variant_permalink } } }) => {
            return (
              <ProductDetailComponent
                product_grouping_permalink={permalink}
                variant_permalink={variant_permalink} />
            );
          }} />
        <Route
          path="/store/cart_share/:cart_share_id"
          render={({ match: { params: { cart_share_id } } }) => <CartShareComponent cart_share_id={cart_share_id} />} />

        {/***
          * PLP pages
        */}
        <Route path="/store/category/:category/:type/:subtype" component={RedirectCategories} />
        <Route path="/store/category/:category/:type" component={RedirectCategories} />
        <Route
          path="/store/category/:category_permalink"
          render={({ location, match: { params: { category_permalink } } }) => renderPLP({
            location, identifier: category_permalink, base: 'hierarchy_category', hierarchy_category: category_permalink
          })} />
        <Route
          path="/store/promos/5centdeal"
          render={({ location }) => renderPLP({
            location, identifier: 'two_for_one', base: 'promo_list', only_two_for_one: true, list_type: 'two_for_one'
          })} />
        <Route
          path="/store/promos/:tag"
          render={({ location, match: { params: { tag } } }) => renderPLP({
            location, identifier: tag, base: 'tag', tag
          })} />
        <Route
          path="/store/search/:term"
          render={({ location, match: { params: { term } } }) => renderPLP({
            location, identifier: term, base: 'search', query: term
          })} />
        <Route
          path="/store/products/case-deals"
          render={({ location }) => renderPLP({
            location, only_case_deals: true, list_type: 'case-deals', base: 'list_type'
          })} />
        <Route
          path="/store/products/popular-products"
          render={({ location }) => renderPLP({
            location, recommended: true, exclude_previous: true, list_type: 'recommended', base: 'list_type'
          })} />
        <Route
          path="/store/products/previous-purchases"
          render={({ location }) => renderPLP({
            location, identifier: 'previous-purchases', only_previous: true, base: 'reorder', list_type: 'reorder'
          })} />
        <Route
          path="/store/products"
          render={({ location }) => renderPLP({
            location, identifier: 'all-items'
          })} />
        <Route
          path="/store/brand/:brand"
          render={({ location, match: { params: { brand } } }) => renderPLP({
            location, identifier: brand, base: 'brand', brand
          })} />
        {/***
          *
          */}
        <Route
          path="/store/content/:content_layout_name"
          render={({ match: { params: { content_layout_name } } }) => {
            const Layout = GenericContentLayoutComponent(getWebLayout(content_layout_name));
            return <Layout />;
          }} />

        <Route path="/store/vineyard-select" component={GenericContentLayoutComponent(getWebLayout('vineyard-select'))} />
        <Route path="/store/cocktails" component={Cocktails} />

        {/* store home fallback if route not found under /store */}
        <Route path="/store" component={GenericContentLayoutComponent(getWebLayout('home'))} />
        {/* redirect to rails if not found in react-router */}
        <Route component={({ location }) => {
          useEffect(() => {
            window.location.href = `${location.pathname}${location.search && `?${location.search}`}`;
          }, []);
          return null;
        }} />
      </Switch>
      <ModalQueue />
    </ScrollToTop>
  );
};

const MainWrapped = withRouter(Main);

const App = () => {
  return (
    <PersistGate loading={null} persistor={persistor}>
      <Provider store={store}>
        <ConnectedRouter history={history}>
          <MainWrapped />
        </ConnectedRouter>
      </Provider>
    </PersistGate>
  );
};

export default App;
