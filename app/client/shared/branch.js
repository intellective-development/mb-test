import _ from 'lodash';

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
  if (window.branch && !_.isUndefined(window.branch.setIdentity) &&
      (window.User || window.Entry)
  ){
    branch.setIdentity(getReferralCode(), {});
  }
}
