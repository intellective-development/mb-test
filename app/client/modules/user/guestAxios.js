import Axios from 'axios';

const guestAxiosInstance = Axios.create();

export default guestAxiosInstance;

const storage = {
  new_user: undefined,
  new_user_token: '',
  user_token: ''
};

window.User = {
  get: (key) => {
    return storage[key];
  },
  set: (key, value) => {
    storage[key] = value;
  }
};

export const guestCallWrapper = fn => (...args) => {
  const alreadySet = window.User.get('user_token');
  if (!alreadySet){
    window.User.set('user_token', window.User.get('new_user_token'));
  }
  return fn(...args)
    .then(data => {
      if (!alreadySet){
        window.User.set('user_token', '');
      }
      return data;
    })
    .catch(e => {
      if (!alreadySet){
        window.User.set('user_token', '');
      }
      throw e;
    });
};
