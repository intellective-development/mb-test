import _ from 'lodash';

const formatPriceString = (price, truncate) => {
  const precision = (truncate && price % 1 === 0) ? 0 : 2;
  const decimal_price = price.toFixed(precision);
  return `$${decimal_price}`;
};

const formatCurrency = (amount, {use_free = false, truncate = false} = {}) => {
  const float_price = parseFloat(amount);
  let formatted_price;
  if (_.isNaN(float_price)){
    if (typeof Raven !== 'undefined'){
      Raven.captureMessage('NaN currency', {extra: {original_price: amount, float_price, use_free, truncate}});
    }
    formatted_price = '';
  } else if (use_free && float_price === 0){
    formatted_price = 'Free';
  } else {
    formatted_price = formatPriceString(amount, truncate);
  }
  return formatted_price;
};

export default formatCurrency;
