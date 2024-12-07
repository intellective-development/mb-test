// @flow
import $ from 'jquery';
import _ from 'lodash';
import _cookie from 'jquery.cookie'; // imports it, but we reference it from $.cookie

// this module is an attempt to normalize our use of cookies throughout the app.
// TODO: move away from jquery.cookie as the underlying implementation.
// TODO: enable secure cookies

export const set = (key: string, val: any, ...options: Array<any>) => {
  $.cookie.json = true; // this probably doesn't need to be set everytime, but it can't hurt
  $.cookie(key, val, ...options);
};

export const get = (key: string, ...options: Array<any>) => {
  $.cookie.json = true;

  let cookie;
  try {
    cookie = $.cookie(key, ...options);
  } catch (ex){
    // if somehow we have a non-json encoded cookie, $.cookie will fail when it attempts to parse the val as json
    Raven.captureException(ex);
    Raven.captureMessage('Cookie parse error', {extra: {key}});
    console.error('Cookie parse error', {extra: {key}});

    cookie = null;
  }

  return cookie;
};

export const remove = (key: string, ...options: Array<any>) => {
  $.removeCookie(key, ...options);
};

// Simply checks for presence of the named cookie. We disable JSON parsing as we do not really
// care about the content, just that it exists.
export const isPresent = (key: string) => {
  $.cookie.json = false;
  return !(_.isNil($.cookie(key)));
};
