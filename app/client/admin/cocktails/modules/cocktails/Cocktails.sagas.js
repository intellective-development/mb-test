import { takeEvery, call, put } from 'redux-saga/effects';
import { fetchCocktailsList, fetchCocktail, postCocktail } from '../../../admin_api';
import { GetCocktailRoutine, GetCocktailsRoutine, SetCocktailRoutine, stringifyItem } from './Cocktails.dux';

export default function* cocktailsWatcherSaga(){
  yield takeEvery(GetCocktailsRoutine.TRIGGER, getCocktails);
  yield takeEvery(GetCocktailRoutine.TRIGGER, getCocktail);
  yield takeEvery(SetCocktailRoutine.TRIGGER, setCocktail);
}

function* getCocktails(){
  try {
    const payload = yield call(fetchCocktailsList);
    yield put(GetCocktailsRoutine.success(payload));
  } catch (e){
    yield put(GetCocktailsRoutine.failure(e));
  }
  yield put(GetCocktailsRoutine.fulfill());
}

function* getCocktail({ payload: cocktail }){
  try {
    yield put(GetCocktailRoutine.success(yield call(fetchCocktail, cocktail)));
  } catch (e){
    yield put(GetCocktailRoutine.failure(e));
  }
  yield put(GetCocktailRoutine.fulfill(cocktail));
}

function* setCocktail({ payload: cocktail }){
  try {
    yield put(SetCocktailRoutine.success(yield call(postCocktail, stringifyItem(cocktail))));
  } catch (e){
    yield put(SetCocktailRoutine.failure(e));
  }
  yield put(SetCocktailRoutine.fulfill(cocktail));
}
