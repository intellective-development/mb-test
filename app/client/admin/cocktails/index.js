import React from 'react';
import { Route } from 'react-router-dom';
import { ConnectedRouter } from 'connected-react-router';
import history from 'shared/utils/history';
import ReduxToastr from 'react-redux-toastr';
import CocktailScreen from './screens/CocktailScreen';
import ToolsListScreen from './screens/ToolsListScreen';
import ToolScreen from './screens/ToolScreen';

const App = ({ match }) => (
  <ConnectedRouter history={history}>
    <Route path={`${match.url}/edit/:cocktailId`} component={CocktailScreen} />
    <Route exact path={`${match.url}/tools`} component={ToolsListScreen} />
    <Route exact path={`${match.url}/tools/edit/:toolId`} component={ToolScreen} />
    <ReduxToastr
      timeOut={4000}
      newestOnTop={false}
      preventDuplicates
      position="top-left"
      transitionIn="fadeIn"
      transitionOut="fadeOut"
      progressBar />
  </ConnectedRouter>
);

export default App;
