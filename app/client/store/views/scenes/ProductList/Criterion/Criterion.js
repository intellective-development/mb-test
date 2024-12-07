import { includes, toLower } from 'lodash';
import React from 'react';
import PropTypes from 'prop-types';
import './Criterion.scss';

export const Criterion = ({
  className,
  criterion,
  description,
  group,
  onClick,
  term,
  type,
  ...props
}) => {
  const checked = includes(criterion, term);

  let criterionName = description;

  if (toLower(description) === 'cbd'){
    criterionName = 'CBD';
  }

  return (
    <li
      className={className}>
      <input
        {...props}
        checked={checked}
        id={term}
        name={group}
        onClick={onClick}
        type={type} />
      <label
        htmlFor={term}
        title={criterionName}>
        {criterionName}
      </label>
    </li>
  );
};

Criterion.defaultProps = {
  className: 'criterion',
  criterion: [],
  group: null,
  type: 'checkbox'
};

Criterion.displayName = 'Criterion';

Criterion.propTypes = {
  className: PropTypes.string,
  criterion: PropTypes.array,
  description: PropTypes.string.isRequired,
  group: PropTypes.string,
  term: PropTypes.oneOfType([
    PropTypes.number,
    PropTypes.string
  ]).isRequired,
  type: PropTypes.string
};
