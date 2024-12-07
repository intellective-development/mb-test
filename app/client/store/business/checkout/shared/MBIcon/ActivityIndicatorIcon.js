import React from 'react';
import colors from '../MBElements/MBColors.css.json';

const ActivityIndicatorIcon = ({ color, ...props }) => (
  <svg
    version="1"
    viewBox="0 0 120 120"
    xmlns="http://www.w3.org/2000/svg"
    xmlnsXlink="http://www.w3.org/1999/xlink"
    {...props}>
    <defs>
      <path
        d="M60 11v16"
        id="l"
        stroke={color}
        strokeLinecap="round"
        strokeWidth="11">
        <animateTransform
          additive="sum"
          attributeName="transform"
          calcMode="discrete"
          dur="1s"
          keyTimes="0;.0833;.1666;.25;.3333;.4166;.5;.5833;.6666;.75;.8333;.9166;1"
          repeatCount="indefinite"
          type="rotate"
          /* eslint-disable-next-line max-len */
          values="0 60,60;30 60,60;60 60,60;90 60,60;120 60,60;150 60,60;180 60,60;210 60,60;240 60,60;270 60,60;300 60,60;330 60,60;360 60,60" />
      </path>
    </defs>
    <use
      opacity=".33"
      transform="rotate(30 60 60)"
      xlinkHref="#l" />
    <use
      opacity=".33"
      transform="rotate(60 60 60)"
      xlinkHref="#l" />
    <use
      opacity=".33"
      transform="rotate(90 60 60)"
      xlinkHref="#l" />
    <use
      opacity=".33"
      transform="rotate(120 60 60)"
      xlinkHref="#l" />
    <use
      opacity=".33"
      transform="rotate(150 60 60)"
      xlinkHref="#l" />
    <use
      opacity=".33"
      transform="rotate(180 60 60)"
      xlinkHref="#l" />
    <use
      opacity=".44"
      transform="rotate(210 60 60)"
      xlinkHref="#l" />
    <use
      opacity=".55"
      transform="rotate(240 60 60)"
      xlinkHref="#l" />
    <use
      opacity=".66"
      transform="rotate(270 60 60)"
      xlinkHref="#l" />
    <use
      opacity=".77"
      transform="rotate(300 60 60)"
      xlinkHref="#l" />
    <use
      opacity=".88"
      transform="rotate(330 60 60)"
      xlinkHref="#l" />
    <use
      xlinkHref="#l" />
  </svg>
);

ActivityIndicatorIcon.defaultProps = {
  color: colors.inlineIcon
};

export default ActivityIndicatorIcon;
