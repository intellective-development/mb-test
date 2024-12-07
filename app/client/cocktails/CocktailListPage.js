import React, { Component } from 'react';
import { connect } from 'react-redux';
import {
  GetCocktailsRoutine,
  GetCocktailsMoreRoutine,
  selectCocktailsBySearch,
  selectCocktailsLoading,
  selectCocktailsHasMoreBySearch
} from '@minibar/store-business/src/cocktails/cocktails.dux';
import CocktailTile from '../store/views/compounds/CocktailScroller/CocktailTile';
import BrowseBreadcrumbs from '../store/views/compounds/BrowseBreadcrumbs';
import { MBLoader } from '../store/views/elements';

class CocktailListPage extends Component {
  componentDidMount(){
    this.props.getCocktails(`${this.props.location.search}`);
    this.listener = window.addEventListener('scroll', () => {
      const { getMoreCocktails, isLoading, hasMore } = this.props;
      if (!isLoading && hasMore && this.bouncer && (this.bouncer.getBoundingClientRect().top < window.innerHeight)){
        getMoreCocktails(`${this.props.location.search}`);
      }
    });
  }

  componentDidUpdate(oldProps){
    if (this.props.location.search !== oldProps.location.search){
      this.props.getCocktails(`${this.props.location.search}`);
    }
  }

  componentWillUnmount(){
    window.removeEventListener('scroll', this.listener);
  }

  render(){
    const { cocktails = [], isLoading } = this.props;
    return ([
      <div className="cocktails-list _pad_sides el-mblayouts-sg">
        <div className="el-mblayouts-sg scPDP_BreadcrumbContainer">
          <BrowseBreadcrumbs breadcrumbs={[{
            description: 'home',
            destination: '/'
          }, {
            description: 'cocktails',
            destination: '/store/cocktails'
          }]} />
        </div>
        <div className="cocktail-list-grid">
          {cocktails.map(renderCocktail)}
        </div>
      </div>,
      <div ref={bouncer => { this.bouncer = bouncer; }} />,
      isLoading ? (
        <div className="panel__wrapper">
          <div className="panel--loader">
            <MBLoader />
          </div>
        </div>
      ) : null
    ]);
  }
}

const CocktailListPageSTP = (state, props) => ({
  cocktails: selectCocktailsBySearch(state)(`${props.location.search}`),
  isLoading: selectCocktailsLoading(state),
  hasMore: selectCocktailsHasMoreBySearch(state)(`${props.location.search}`)
});

const CocktailListPageDTP = {
  getCocktails: GetCocktailsRoutine.trigger,
  getMoreCocktails: GetCocktailsMoreRoutine.trigger
};

export default connect(
  CocktailListPageSTP,
  CocktailListPageDTP,
)(CocktailListPage);

export const renderCocktail = (props) => {
  return (<CocktailTile key={props.id} {...props} />);
};
