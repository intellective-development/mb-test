// @flow

import * as React from 'react';

// note that this inexact type allows us to pass as much info as we'd like
type ExtraErrorData = {
  location: string
};

type MBErrorBoundaryProps = {
  children: React.Node,
  errorData: (error: Object, info: Object) => ExtraErrorData
}
type MBErrorBoundaryState = {
  has_error: boolean
};

export class MBErrorBoundary extends React.Component<MBErrorBoundaryProps, MBErrorBoundaryState> {
  state = { has_error: false }

  componentDidCatch(error: Error, info: Object){
    this.setState({ has_error: true });

    // sanity check, errorData really should always be set
    const extra_data = this.props.errorData ? this.props.errorData(error, info) : {};
    Raven.captureException(error, {
      extra: { react_info: info, ...extra_data}
    });
  }

  render(){
    if (this.state.has_error) return null;

    return this.props.children;
  }
}

export default MBErrorBoundary;
