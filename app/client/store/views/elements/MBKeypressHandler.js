// @flow
import * as React from 'react';
import _ from 'lodash';

const KEY_CODES = {
  enter: 13,
  up_arrow: 38,
  down_arrow: 40
};

const KEY_CODE_NAMES = _.invert(KEY_CODES);

type KeyHandlers = { [$Keys<KEY_CODES>]: () => void };

type RenderParams = {
  onKeyDown: (SyntheticKeyboardEvent<HTMLInputElement>) => void
}

type Props = {
  key_handlers: KeyHandlers,
  render: (RenderParams) => React.Node,
}

const makeHandler = (key_handlers: KeyHandlers) => (event: SyntheticKeyboardEvent<HTMLInputElement>) => {
  const key_code = event.keyCode;
  const handler = key_handlers[KEY_CODE_NAMES[key_code]];

  if (handler){
    event.preventDefault();
    handler(event);
  }
};

const KeypressHandler = ({ key_handlers, render }: Props) => {
  const WithKeypressHandling = render({ onKeyDown: makeHandler(key_handlers) });

  return WithKeypressHandling;
};

export default KeypressHandler;
