// @flow

import classNames from 'classnames/bind';

// This utility provides a thin wrapper around the classnames library to ensure
// That we are using its bound variant.
// It also provides us with an easy way to customize classnames in the future if we so desire.

const bindClassNames = (styles: Object) => classNames.bind(styles);

export default bindClassNames;
