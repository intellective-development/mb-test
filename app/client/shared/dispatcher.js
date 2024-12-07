import Rx from 'rxjs';

const dispatch_stream = new Rx.Subject();

export function dispatchAction(payload){
  dispatch_stream.next(payload);
}

export function actionStream(actionType){
  return dispatch_stream.filter(payload => payload.actionType === actionType);
}

export default dispatch_stream; // TODO: convert to obs, not subject
