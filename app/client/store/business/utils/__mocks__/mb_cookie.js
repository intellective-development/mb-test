// @flow

import _ from 'lodash';

let cookies = {};

export const set = jest.fn((key: string, val: any) => {
  cookies = {
    ...cookies,
    [key]: val
  };
});

export const get = jest.fn((key: string) => {
  return cookies[key];
});

export const remove = jest.fn((key: string) => {
  cookies = _.omit(cookies, key);
});

export const __clear = () => {
  set.mockClear();
  get.mockClear();
  remove.mockClear();
  cookies = {};
};

export const __setAll = (next_cookies: Object) => {
  cookies = next_cookies;
};
