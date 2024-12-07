// @flow

import { startsWith, get } from 'lodash';
import { createStore, applyMiddleware, compose } from 'redux';
import { createEpicMiddleware } from 'redux-observable';
import { procedureMiddleware } from 'redux-procedures';
import { routerMiddleware } from 'connected-react-router';
import createSagaMiddleware from 'redux-saga';
import { persistStore, persistReducer } from 'redux-persist';
import storage from 'redux-persist/lib/storage';
import LogRocket from 'logrocket';
import configureApi from './business/networking/configure_api';
import baseEpic from './business/epics';
import baseReducer from './business/base_reducer';
import rootSaga from './business/sagas';
import { getBootstrappedState } from './business/session';
import { supplier_middleware } from './business/supplier';
import { analytics_middlewares } from './business/analytics';
import history from '../shared/utils/history';

const composeEnhancers = (process.env.NODE_ENV === 'development' && window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ &&
window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__({ trace: true, traceLimit: 25 })) || compose;
configureApi();
const sagaMiddleware = createSagaMiddleware();

const persistConfig = {
  key: 'root',
  whitelist: [
    'supplier',
    'product_grouping',
    'variant',
    'delivery_method'
  ],
  storage
};

const persistedReducer = persistReducer(persistConfig, baseReducer);

const configureStore = () => {
  // when server rendering, provide only the most basic store
  // TODO: better story for server rendering
  if (process.env.RENDER_ENV === 'server') return createStore(baseReducer);

  const initial_state = getBootstrappedState();
  const epicMiddleware = createEpicMiddleware(baseEpic);
  // const migrationEnhancer = persistence_migration.mbCreateMigration(persistence_migration.MIGRATION_MANIFEST);
  // const persistenceEnhancer = compose(migrationEnhancer, autoRehydrate());

  const middlewares = [
    analytics_middlewares.sentry,
    supplier_middleware.make(),
    store => next => action => {
      if (action.type === '@@router/LOCATION_CHANGE'){
        const oldpathname = get(store.getState(), 'router.location.pathname', '');
        const {pathname, search} = get(action, 'payload.location', {});
        if (!startsWith(oldpathname, '/store') && pathname !== oldpathname){
          window.location.href = pathname + search;
        }

        let canonical = document.querySelector('link[rel="canonical"]');
        if (!canonical){
          canonical = document.createElement('link');
          canonical.setAttribute('rel', 'canonical');
          document.head.appendChild(canonical);
        }
        canonical.setAttribute('href', `https://minibardelivery.com${window.location.pathname}`);
      }
      return next(action);
    },
    routerMiddleware(history),
    epicMiddleware,
    sagaMiddleware,
    procedureMiddleware,
    LogRocket.reduxMiddleware()
  ];

  const store_enhancers = [
    applyMiddleware(...middlewares)
  ];

  const store = createStore(
    persistedReducer,
    initial_state,
    composeEnhancers(...store_enhancers)
  );

  sagaMiddleware.run(rootSaga);

  return store;
};

// this singleton should be used with caution!
const store = configureStore();

export const persistor = persistStore(store);

export default store;

window.__store = store;
