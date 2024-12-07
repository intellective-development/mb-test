import { isSearchSwitchFetching } from '../selectors';

describe('getContentLayoutStatus', () => {
  it('returns true if the search_switch request is LOADING', () => {
    const state = {
      request_status: { by_id: { bar: 'LOADING' }, by_action: { 'SEARCH_SWITCH:FETCH': { foo: 'bar' } }}
    };
    expect(isSearchSwitchFetching(state, 'foo')).toEqual(true);
  });

  it('returns true if the search_switch request is in another state', () => {
    const state = {
      request_status: { by_id: { bar: 'SUCCESS' }, by_action: { 'SEARCH_SWITCH:FETCH': { foo: 'bar' } }}
    };
    expect(isSearchSwitchFetching(state, 'foo')).toEqual(false);
  });
});
