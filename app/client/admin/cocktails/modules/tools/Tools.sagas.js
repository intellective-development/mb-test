import { takeEvery, call, put } from 'redux-saga/effects';
import { fetchToolsList, fetchTool, postTool } from '../../../admin_api';
import { GetToolRoutine, GetToolsRoutine, SetToolRoutine, stringifyItem } from './Tools.dux';

export default function* toolsWatcherSaga(){
  yield takeEvery(GetToolsRoutine.TRIGGER, getTools);
  yield takeEvery(GetToolRoutine.TRIGGER, getTool);
  yield takeEvery(SetToolRoutine.TRIGGER, setTool);
}

function* getTools(){
  try {
    const payload = yield call(fetchToolsList);
    yield put(GetToolsRoutine.success(payload));
  } catch (e){
    yield put(GetToolsRoutine.failure(e));
  }
  yield put(GetToolsRoutine.fulfill());
}

function* getTool({ payload: tool }){
  try {
    yield put(GetToolRoutine.success(yield call(fetchTool, tool)));
  } catch (e){
    yield put(GetToolRoutine.failure(e));
  }
  yield put(GetToolRoutine.fulfill(tool));
}

function* setTool({ payload: tool }){
  try {
    yield put(SetToolRoutine.success(yield call(postTool, stringifyItem(tool))));
  } catch (e){
    yield put(SetToolRoutine.failure(e));
  }
  yield put(SetToolRoutine.fulfill(tool));
}
