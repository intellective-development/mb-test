import {
  applyMiddleware,
  createStore,
  compose
} from 'redux';
import { routerMiddleware } from 'connected-react-router';
import createSagaMiddleware from 'redux-saga';
import history from '../shared/utils/history';
import rootReducer from './reducers';
import rootSaga from './sagas';

const composeEnhancers = (window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ &&
  window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__({ trace: true, traceLimit: 25 })) || compose;

const sagaMiddleware = createSagaMiddleware();

export const configureStore = () => {
  const store = createStore(
    rootReducer,
    composeEnhancers(
      applyMiddleware(
        routerMiddleware(history),
        sagaMiddleware
        /*** other middlewares here ***/
      )
    )
  );

  sagaMiddleware.run(rootSaga);

  return store;
};

export default configureStore();

