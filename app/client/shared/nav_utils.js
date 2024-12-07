import React from 'react';
import { Link as RRLink } from 'react-router-dom';

const unslashPath = (path) => path.replace('//', '/');

export const Link = ({ to, ...props }) => <RRLink to={unslashPath(to)} {...props} />;
