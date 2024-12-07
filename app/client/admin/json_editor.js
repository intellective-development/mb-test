import * as React from 'react';
import Json from '@minibar/react-json';

const DEFAULT_VALUE = {};

const JsonEditor = ({value, callback}) => (
  <div>
    <Json value={value || DEFAULT_VALUE} onChange={callback} />
  </div>
);

export default JsonEditor;
