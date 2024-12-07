// @flow
import type { Middleware } from 'redux';

const mock_raven = { captureBreadcrumb: (_action) => { console.warn('Couldn\'t find Raven on window'); } };
const raven = global.Raven || mock_raven;

export const sentry: Middleware<any, any> = () => (next) => (action) => {
  // Raven.captureBreadcrumb() is not a function on sandbox
  raven.captureBreadcrumb && raven.captureBreadcrumb({
    category: 'redux',
    message: action.type
  });

  return next(action);
};
