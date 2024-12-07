import { fork, all } from 'redux-saga/effects';
import { routinePromiseWatcherSaga } from 'redux-saga-routines';
import { cocktailsSagaWatcher } from './cocktails';

export default function* rootSaga(){
  yield all([
    yield fork(cocktailsSagaWatcher),
    yield fork(routinePromiseWatcherSaga)
  ]);
}
