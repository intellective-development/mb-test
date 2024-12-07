import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';
import fonts from './MBElements/MBFonts.css.json';
import styles from '../Checkout.css.json';

export const ProgressBar = ({ step }) => (
  <svg
    className={css([
      fonts.common,
      styles.progressbar
    ])}
    version="1"
    viewBox="0 0 256 64"
    xmlns="http://www.w3.org/2000/svg">
    {step === 1 && (
      <g id="step-1">
        <g fill="#000" stroke="#000">
          <path d="M64 24h128" stroke="#ddd" />
          <circle cx="64" cy="24" r="8" fill="#fff" />
          <circle cx="192" cy="24" r="8" fill="#fff" stroke="#ddd" />
        </g>
        <g fill="#222">
          <text x="64" y="50">Information</text>
          <text x="192" y="50" fill="#ddd">Complete Purchase</text>
        </g>
      </g>
    )}

    {step === 2 && (
      <g id="step-2">
        <g fill="#000" stroke="#000">
          <path d="M64 24h128" />
          <circle cx="64" cy="24" r="8" />
          <circle cx="192" cy="24" r="8" fill="#fff" />
        </g>
        <g fill="#222">
          <text x="64" y="50">Information</text>
          <text x="192" y="50">Complete Purchase</text>
        </g>
        <g
          fill="none"
          stroke="#fff"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2">
          <path d="M59 25l3 3 7-7" />
        </g>
      </g>
    )}

    {step === 3 && (
      <g id="step-3">
        <g fill="#000" stroke="#000">
          <path d="M64 24h128" />
          <circle cx="64" cy="24" r="8" />
          <circle cx="192" cy="24" r="8" />
        </g>
        <g fill="#222">
          <text x="64" y="50">Information</text>
          <text x="192" y="50">Complete Purchase</text>
        </g>
        <g
          fill="none"
          stroke="#fff"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2">
          <path d="M59 25l3 3 7-7" />
          <path d="M187 25l3 3 7-7" />
        </g>
      </g>
    )}
  </svg>
);

ProgressBar.defaultProps = {
  step: 1
};

ProgressBar.displayName = 'ProgressBar';

ProgressBar.propTypes = {
  step: PropTypes.number
};

export default ProgressBar;
