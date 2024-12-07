import React, { useState } from 'react';
import LoginPopupForm from './LoginPopupForm';
import RecoverPopupForm from './RecoverPopupForm';

const PopupForm = ({ email }) => {
  const [state, setState] = useState();
  switch (state){
    case 'recover':
      return (<RecoverPopupForm email={email} goToLogin={() => setState('login')} />);
    case 'login':
    default:
      return (<LoginPopupForm email={email} goToResetPassword={() => setState('recover')} />);
  }
};

export default PopupForm;
