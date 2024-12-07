import {
  isModalShowing,
  shouldShowModal,
  isLoading,
  modalStatus,
  error
} from '../selectors';

describe('isModalShowing', () => {
  it('returns the email_capture_modal in state', () => {
    const state = { is_showing_modal: false };
    expect(isModalShowing(state)).toEqual(false);
  });
});

describe('shouldShowModal', () => {
  it('returns whether should show email_capture_modal', () => {
    const state = { should_show_modal: false };
    expect(shouldShowModal(state)).toEqual(false);
  });
});

describe('isLoading', () => {
  it('returns true if loading in state is true', () => {
    const state = {loading: true};
    expect(isLoading(state)).toEqual(true);
  });
});

describe('modalStatus', () => {
  it('returns intial if status in state is initial', () => {
    const state = {status: 'initial'};
    expect(modalStatus(state)).toEqual('initial');
  });
});

describe('error', () => {
  it('returns error message if error in state is present', () => {
    const state = {error: 'error'};
    expect(error(state)).toEqual('error');
  });
  it('returns an empty string if error in state is not', () => {
    const state = {error: ''};
    expect(error(state)).toEqual('');
  });
});
