import { sortKVPairsByKeys } from '../helpers';

describe('sorting filter keys', () => {
  it('should alphabetize unknown keys', () => {
    const keys = [['foo', 1], ['bar', 3], ['baz', 2], ['lorem', 4]];
    const order = [];
    const sorted_keys = keys.sort(sortKVPairsByKeys(order));
    expect(sorted_keys).toEqual([['bar', 3], ['baz', 2], ['foo', 1], ['lorem', 4]]);
  });

  it('should sort according to the passed in order', () => {
    const keys = [['foo', 1], ['bar', 3], ['baz', 2], ['lorem', 4]];
    const order = ['lorem', 'foo', 'baz', 'bar'];
    const sorted_keys = keys.sort(sortKVPairsByKeys(order));
    expect(sorted_keys).toEqual([['lorem', 4], ['foo', 1], ['baz', 2], ['bar', 3]]);
  });

  it('should sort according to the passed in order and then alphabetize remaining unknown keys', () => {
    const keys = [['foo', 1], ['bar', 3], ['baz', 2], ['lorem', 4]];
    const order = ['lorem', 'bar'];
    const sorted_keys = keys.sort(sortKVPairsByKeys(order));
    expect(sorted_keys).toEqual([['lorem', 4], ['bar', 3], ['baz', 2], ['foo', 1]]);
  });
});
