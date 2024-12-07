function getEmail(){
  let email;

  if (window.User){
    email = window.User.get('email');
  } else if (window.Entry && window.Entry.User){
    email = window.Entry.User.email;
  }

  return email;
}

function getReferralCode(){
  let referral_code;

  if (window.User){
    referral_code = window.User.get('referral_code');
  } else if (window.Entry && window.Entry.User){
    referral_code = window.Entry.User.referral_code;
  }

  return referral_code;
}

export default function(){
  if (typeof Raven !== 'undefined' && (window.User || window.Entry)){
    Raven.setUser({
      email: getEmail(),
      username: getReferralCode()
    });
  }
}
