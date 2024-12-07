import sessionStorageSupported from 'shared/utils/check_storage_supported';

// TODO: This is deprecated, and should no longer be used. Long term we'd like to use
// Some sort of query param based system with this that we could share with app.

const local_storage_key = 'promo_code';

export function setPromoCode(promo){
  if (sessionStorageSupported){
    sessionStorage.setItem(local_storage_key, promo);
  }
}

export function getPromoCode(){
  let promo_code;
  if (sessionStorageSupported && sessionStorage.getItem(local_storage_key)){
    promo_code = sessionStorage.getItem(local_storage_key);
  }
  return promo_code;
}

export function removePromoCode(){
  if (sessionStorageSupported){
    sessionStorage.removeItem(local_storage_key);
  }
}
