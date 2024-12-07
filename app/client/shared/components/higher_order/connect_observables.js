// @flow

import * as React from 'react';
import _ from 'lodash';
import Rx from 'rxjs';
import type { Observable } from 'rxjs';

// TODO: this should not have an intermediate subject. Find a different way
// testing with replay https://jsbin.com/moyitu/edit?js,console
export function replayLatest(observable: Observable<*>){
  const latestStream = new Rx.ReplaySubject(1);
  observable.subscribe(latestStream);
  return latestStream;
}

// state_observable_map has keys that will = the state key, and the value an observable stream to subscribe to
export default function connectToObservables(
  WrappedComponent: React.ComponentType<*>,
  state_observable_map: {[string]: Observable<*>
} = {}){
  class ObservableConnection extends React.Component<*, *> {
    subscriptions = []

    componentDidMount(){ // TODO: make this cWM/constructor
      this.subscriptions = _.map(state_observable_map, (observable, state_key) => {
        const subscription = observable.subscribe((new_val) => {
          this.setState({ [state_key]: new_val });
        });
        return subscription;
      });
    }
    componentWillUnmount(){
      this.subscriptions.forEach(subscription => subscription.unsubscribe());
    }
    render(){
      return <WrappedComponent {...this.props} {...this.state} />;
    }
  }

  return ObservableConnection;
}
