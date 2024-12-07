import * as React from 'react';
// This component is for places like modals and other notifications where we want it to show
// whenever there is a new value in a stream (like an error stream), but be dimissible from Component.

// The new value and the dimissed state need to live on the same level, so that a new value
// can overwrite the dismissed state, but the dismissed state will stick even if Component's
// parent re-renders.

// TODO: come up with a better name for this
export default function showOnStreamEmit(Component, observable, value_name = 'value'){
  class ObservableConnection extends React.Component {
    constructor(props){
      super(props);
      this.state = {show: false};
    }

    componentDidMount(){
      this.subscription = observable.subscribe(new_val => {
        this.setState({
          show: true,
          [value_name]: new_val.content // this is the content of the source observable. name customizable
        });
      });
    }

    componentWillUnmount(){
      this.subscription.unsubscribe();
    }

    dismiss = () => {
      this.setState({show: false});
    };

    render(){
      return <Component {...this.props} {...this.state} dismiss={this.dismiss} />;
    }
  }

  return ObservableConnection;
}
