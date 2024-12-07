import { combineReducers } from 'redux';
import { reducer as form } from 'redux-form';
import { connectRouter } from 'connected-react-router';
import { reducer as toastr } from 'react-redux-toastr';
import cocktails from './cocktails/modules/cocktails/Cocktails.dux';
import tools from './cocktails/modules/tools/Tools.dux';
import history from '../shared/utils/history';
/*import app from '../modules/App';
import { reducer as buildings } from '../modules/Buildings/Buildings.dux';
import { reducer as systems } from '../modules/Systems/Systems.dux';
import { reducer as boards } from '../modules/Boards/Boards.dux';
import { reducer as users } from '../modules/Users/Users.dux';*/

const router = connectRouter(history);

export default combineReducers({
  form,
  router,
  cocktails,
  tools,
  toastr
});
