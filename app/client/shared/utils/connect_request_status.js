// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import isShallowEqualObject from 'shallow-equal/objects';
import type { Action } from '@minibar/store-business/src/constants';

import { SUCCESS_STATUS, ERROR_STATUS } from '@minibar/store-business/src/utils/fetch_status';
import { request_status_selectors } from 'store/business/request_status';
import type { RequestStatus } from 'store/business/request_status';

// This Component provides an abstraction around the request_status slice of state, enabling its wrapped component to make a "trackable" request.
// The wrapped component can pass an appropriate action, as well as success and error callbacks, and expect them to be called when the state updates to reflect that status.

type Request = {
  request_id: string,
  onSuccess: () => any,
  onError: () => any
};

type RequestStatusProps = {
  request_statuses: {[string]: RequestStatus}
}

const connectRequestStatus = (WrappedComponent: React.ComponentType<*>) => {
  const wrapped_component_name: string = WrappedComponent.displayName || WrappedComponent.name || 'Component';

  class RequestStatusTracker extends React.Component<RequestStatusProps> {
    static displayName = `connectRS(${wrapped_component_name})`

    requests: Array<Request> = [];

    // since this is subscribed to the entire request_statuses object, we implement a custom
    // sCU to prevent unnecessary render cycles when unrelated requests are updated
    shouldComponentUpdate(next_props: RequestStatusProps){
      const { request_statuses, ...rest_props } = this.props;
      const { request_statuses: next_request_statuses, ...next_rest_props } = next_props;

      // update if any other props have changed
      if (!isShallowEqualObject(rest_props, next_rest_props)) return true;

      // otherwise, update only if one of this component's requests' states has updated
      const request_status_change = this.requests.some(({request_id}) => (
        request_statuses[request_id] !== next_request_statuses[request_id]
      ));

      return request_status_change;
    }

    // we run the callbacks in componentDidUpdate to give the child components a chance to receive their state updates
    componentDidUpdate(){
      this.requests.forEach((request) => {
        const {request_id, onSuccess, onError} = request;
        const request_state = this.props.request_statuses[request_id];

        if (request_state === SUCCESS_STATUS){
          this.removeRequest(request);
          onSuccess();
        } else if (request_state === ERROR_STATUS){
          this.removeRequest(request);
          onError();
        }
      });
    }

    addRequest = (new_request) => {
      this.requests = [...this.requests, new_request];
    }
    removeRequest = (new_request) => {
      this.requests = _.without(this.requests, new_request);
    }

    trackRequestStatus = (action: Action, onSuccess: Function, onError: Function) => {
      const request_id = _.get(action, 'meta.request_data.request_id');

      if (!request_id) throw new Error('Invalid Action: No request_id specified.');

      const new_request = {request_id, onSuccess, onError};
      this.addRequest(new_request);
    }

    render(){
      const child_props = _.omit(this.props, 'request_statuses');

      return <WrappedComponent {...child_props} trackRequestStatus={this.trackRequestStatus} />;
    }
  }

  const RequestStatusTrackerSTP = (state) => ({request_statuses: request_status_selectors.getAllRequestStatuses(state)});
  const RequestStatusTrackerContainer = connect(RequestStatusTrackerSTP)(RequestStatusTracker);

  return RequestStatusTrackerContainer;
};

export default connectRequestStatus;
