import { config } from 'store/business/session';

export default function(user_token){
  // note that initial_access_token may be client_credentials or resource_owner,
  // depending on the logged in state of the user when the store app starts,
  // and that it will not be updated if the user signs in/up
  const { initial_access_token } = config;

  if (initial_access_token){
    $.ajaxSetup({
      headers: {
        'Authorization': `bearer ${initial_access_token}`,
        'X-Minibar-User-Token': user_token
      },
      statusCode: {
        401(){
          // TODO: this will not work outside of the store
          if (typeof MiniBarView !== 'undefined'){
            MiniBarView.showRefreshBox();
          }
        }
      }
    });
  }
}
