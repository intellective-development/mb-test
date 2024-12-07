// @flow

export type WorkingHour = {
  wday: number,
  off: boolean,
  starts_at: string,
  ends_at: string
}

export * as working_hours_helpers from './helpers';
export * as working_hours_actions from './actions';
export { default as workingHoursReducer } from './reducer';
export { default as working_hours_selectors } from './selectors';
