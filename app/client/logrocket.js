import LogRocket from 'logrocket';
import { getMetaContent } from './store/business/session/config';

export const initLogrocket = () => {
  const logrocket = getMetaContent('logrocket');
  if (logrocket){
    LogRocket.init(logrocket);
    console.log('[LogRocket] connected to', logrocket); // eslint-disable-line no-console
    if (window.Data && window.Data.user){
      LogRocket.identify(window.Data.user.user_token, {
        name: `${window.Data.user.first_name} ${window.Data.user.last_name}`,
        email: window.Data.user.email,
        id: window.Data.user.id
      });
      console.log('[LogRocket] identified as', window.Data.user); // eslint-disable-line no-console
    }
  }
};
