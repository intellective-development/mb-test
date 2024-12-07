// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import { GetCocktailsRoutine, selectCocktailsBySearch } from '@minibar/store-business/src/cocktails/cocktails.dux';

function connectCocktailScroller(WrappedComponent: React.ComponentType<*>){
  class CocktailScrollerContainer extends React.Component {
    componentDidMount(){
      this.props.getCocktails(this.props.content_url);
    }

    render(){
      const { action_url, title, ...other_props } = this.props;
      return (
        <WrappedComponent
          title={title}
          action_url={action_url}
          {...other_props} />
      );
    }
  }

  return connect(CocktailScrollerSTP, CocktailScrollerDTP)(CocktailScrollerContainer);
}

const CocktailScrollerSTP = (state, props) => {
  return {
    cocktails: selectCocktailsBySearch(state)(`${props.content_url}`)
  };
};

const CocktailScrollerDTP = {
  getCocktails: GetCocktailsRoutine.trigger
};

export default connectCocktailScroller;
