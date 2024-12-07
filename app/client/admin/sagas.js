import { fork, all } from 'redux-saga/effects';
import { routinePromiseWatcherSaga } from 'redux-saga-routines';
import cocktailsSagas from './cocktails/modules/cocktails/Cocktails.sagas';
import toolsSagas from './cocktails/modules/tools/Tools.sagas';

export default function* rootSaga(){
  yield all([
    yield fork(cocktailsSagas),
    yield fork(toolsSagas),
    yield fork(routinePromiseWatcherSaga)
  ]);
}
