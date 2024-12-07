import Rx from 'rxjs';

export const hasNoItems = () => false;
export const cartStream = new Rx.Observable.of({items: []});
