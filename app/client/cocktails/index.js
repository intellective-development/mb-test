import React from 'react';
import { Route, Switch } from 'react-router-dom';
import CocktailDetailPage from './CocktailDetailPage';
import CocktailListPage from './CocktailListPage';
import makeContentLayout from '../store/views/scenes/GenericContentLayout';
import BrowseBreadcrumbs from '../store/views/compounds/BrowseBreadcrumbs';
import { EmailCapture } from '../store/views/scenes/LandingPage';

const CocktailHomeListPageModuleList = makeContentLayout('Web_Cocktail_Home_Screen');

const CocktailHomeListPage = () => {
  return [
    <div key="breadcrumb" className="el-mblayouts-sg _pad_sides scPDP_BreadcrumbContainer">
      <BrowseBreadcrumbs breadcrumbs={[{
        description: 'home',
        destination: '/'
      }, {
        description: 'cocktails',
        destination: '/store/cocktails'
      }]} />
    </div>,
    <CocktailHomeListPageModuleList key="cocktail-list" can_fetch_without_suppliers />,
    <EmailCapture />
  ];
};
export default () => {
  return (
    <div>
      <Switch>
        <Route
          exact
          path={'/store/cocktails/search'}
          component={CocktailListPage} />
        <Route
          exact
          path={'/store/cocktails/:id'}
          component={CocktailDetailPage} />
        <Route
          exact
          path={'/store/cocktails'}
          component={CocktailHomeListPage} />
      </Switch>
    </div>
  );
};
