// @flow

import immutableInsert from '../immutable_insert';

describe('immutableInsert', () => {
  it('inserts an item into the middle of a list', () => {
    const prev_list = ['a', 'b', 'c'];
    const next_list = immutableInsert(prev_list, 1, 'D');

    expect(next_list).toEqual(['a', 'D', 'b', 'c']);
    expect(prev_list).toEqual(['a', 'b', 'c']);
    expect(next_list).not.toBe(prev_list);
  });

  it('inserts an item into the beginning of a list', () => {
    const prev_list = ['a', 'b', 'c'];
    const next_list = immutableInsert(prev_list, 0, 'D');

    expect(next_list).toEqual(['D', 'a', 'b', 'c']);
    expect(prev_list).toEqual(['a', 'b', 'c']);
    expect(next_list).not.toBe(prev_list);
  });

  it('inserts an item into the end of a list', () => {
    const prev_list = ['a', 'b', 'c'];
    const next_list = immutableInsert(prev_list, 3, 'D');

    expect(next_list).toEqual(['a', 'b', 'c', 'D']);
    expect(prev_list).toEqual(['a', 'b', 'c']);
    expect(next_list).not.toBe(prev_list);
  });

  it('inserts an item after the end of a list', () => {
    const prev_list = ['a', 'b', 'c'];
    const next_list = immutableInsert(prev_list, 10, 'D');

    expect(next_list).toEqual(['a', 'b', 'c', 'D']);
    expect(prev_list).toEqual(['a', 'b', 'c']);
    expect(next_list).not.toBe(prev_list);
  });

  it('inserts multiple items', () => {
    const prev_list = ['a', 'b', 'c'];
    const next_list = immutableInsert(prev_list, 1, 'D', 'E');

    expect(next_list).toEqual(['a', 'D', 'E', 'b', 'c']);
    expect(prev_list).toEqual(['a', 'b', 'c']);
    expect(next_list).not.toBe(prev_list);
  });
});
