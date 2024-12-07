// @flow
import Rx from 'rxjs';

// This is pulled out in order to avoid circular deps with backbone RX, the intention is to
// have this all run through redux anyways!

// TODO: have everything import this as necessary
// TODO: feed this into an epic (?)

const locationStream = new Rx.ReplaySubject(1);

export default locationStream;
