import { compact, size } from 'lodash';

export const formatPhone = (input) => {
  if (!input) return input;

  // FIXME we are assuming that phone number is US-based. Sometimes server prefixes with +1 (such as in pickup details form).
  const n = input.replace(/^\+1/, '').replace(/[^\d]/g, '');

  return compact([
    n.slice(0, 3),
    size(n) > 3 ? n.slice(3, 6) : null,
    size(n) > 5 ? n.slice(6, 10) : null
  ]).join('-');
};

export default formatPhone;
