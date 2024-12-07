import * as React from 'react';
import classNames from 'classnames';

const RaterStar = ({ updateRating, hover, exit, value, hoverScore}) => {
  const raterStarClassName = classNames('rating', { active: value <= hoverScore });

  return (
    <span
      tabIndex={0}
      onClick={updateRating}
      role="button"
      onMouseOver={() => hover(value)}
      onMouseOut={exit}
      className={raterStarClassName}>
      ★
    </span>
  );
};

export default RaterStar;
