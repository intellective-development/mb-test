import React from 'react';
import colors from '../MBElements/MBColors.css.json';

const DateIcon = ({ color, ...props }) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    {...props}>
    <path
      d="M30 18H10v92h100V18H90M10 36h100M39 18h42m15 32H26v46h70M26 65h70M26 81h70M44 50v46m18-46v46m18-46v46M30 10v15h9V10zm51 0v15h9V10z"
      fill="none"
      stroke={color}
      strokeLinejoin="round"
      strokeWidth="4" />
  </svg>
);

DateIcon.defaultProps = {
  color: colors.inlineIcon
};

export default DateIcon;
