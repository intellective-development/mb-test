import { isUndefined } from 'lodash-es';

const dq = '(min-width: 768px)';
const mq = '(max-width: 767px)';

export default (mobile, desktop) =>
  (isUndefined(desktop)
    ? {
      [`@media ${mq}`]: mobile
    }
    : {
      [`@media ${mq}`]: mobile,
      [`@media ${dq}`]: desktop
    });
