import qs from 'qs';

/* eslint-disable */
function decoder(str, defaultDecoder, charset){ 
  const strWithoutPlus = str.replace(/\+/g, " ");
  if (charset === "iso-8859-1"){
    // unescape never throws, no try...catch needed:
    return strWithoutPlus.replace(/%[0-9a-f]{2}/gi, decodeURIComponent);
  }

  if (/^(\d+|\d*\.\d+)$/.test(str)){
    return parseFloat(str);
  }

  const keywords = {
    true: true,
    false: false,
    null: null,
    undefined
  };
  if (str in keywords){
    return keywords[str];
  }

  // utf-8
  try {
    return decodeURIComponent(strWithoutPlus);
  } catch (e){
    return strWithoutPlus;
  }
}
/* eslint-enable */

export const stringify = (obj, options) => {
  return qs.stringify(obj, options);
};

export const parse = (str, options) => {
  return qs.parse(str, { ...options, decoder });
};

export default {
  ...qs,
  parse,
  stringify
};
