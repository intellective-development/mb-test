// @flow

import {
  encodePLPParams,
  decodePLPParams,
  isExternallyNavigable
} from '../utils';

describe('encodePLPParams and decodePLPParams', () => {
  it('handles a param', () => {
    const filter_params = {hierarchy_type: ['wine-red', 'wine-white']};
    const encoded_params = encodePLPParams(filter_params);

    expect(encoded_params).toEqual('hierarchy_type=%5B%22wine-red%22%2C%22wine-white%22%5D');
    expect(decodePLPParams(encoded_params)).toEqual({filter: filter_params, sort: undefined})
  });

  it('encodes a param with a single value', () => {
    const filter_params = {hierarchy_type: ['wine-red']};
    const encoded_params = encodePLPParams(filter_params);

    expect(encoded_params).toEqual('hierarchy_type=%5B%22wine-red%22%5D');
    expect(decodePLPParams(encoded_params)).toEqual({filter: filter_params, sort: undefined})
  });

  it('encodes multiple params', () => {
    const filter_params = {hierarchy_type: ['wine-red'], country: ['usa']};
    const encoded_params = encodePLPParams(filter_params);

    expect(encoded_params).toEqual('hierarchy_type=%5B%22wine-red%22%5D&country=%5B%22usa%22%5D');
    expect(decodePLPParams(encoded_params)).toEqual({filter: filter_params, sort: undefined})
  });

  it('encodes a param and a sort', () => {
    const filter_params = {hierarchy_type: ['wine-red', 'wine-white']};
    const sort = 'price_asc';
    const encoded_params = encodePLPParams(filter_params, sort);

    expect(encoded_params).toEqual('hierarchy_type=%5B%22wine-red%22%2C%22wine-white%22%5D&sort=price_asc');
    expect(decodePLPParams(encoded_params)).toEqual({filter: filter_params, sort})
  });

  it('leaves non filter params alone', () => {
    const filter_params = {hierarchy_type: ['wine-red', 'wine-white']};
    const sort = 'price_asc';
    const original_params = 'hierarchy_type=%5B%22wine-red%22%2C%22wine-white%22%5D&sort=price_asc&utm_source=social';

    expect(decodePLPParams(original_params)).toEqual({filter: filter_params, sort})
  });
});

describe('isExternallyNavigable', () => {
  it('returns true for PDP link', () => {
    expect(isExternallyNavigable('/store/product/sixpoint-crisp')).toEqual(true);
  });

  it('returns true for PDP link with a variant permalink', () => {
    expect(isExternallyNavigable('/store/product/sixpoint-crisp/sixpoint-crisp-6-pack')).toEqual(true);
  });

  it('returns true for brand PLP link', () => {
    expect(isExternallyNavigable('/store/brand/sixpoint')).toEqual(true);
  });

  it('returns false for other urls', () => {
    expect(isExternallyNavigable('/store/')).toEqual(false);
    expect(isExternallyNavigable('/store/cart')).toEqual(false);
    expect(isExternallyNavigable('/store/checkout')).toEqual(false);
    expect(isExternallyNavigable('/store/category/wine')).toEqual(false);
  });
});
