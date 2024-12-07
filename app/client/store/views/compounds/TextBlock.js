// @flow

import * as React from 'react';
import { MBText } from 'store/views/elements';

type TextBlockProps = {
  children: string
}

const TextBlock = ({ children }: TextBlockProps) => {
  if (!children) return null;

  return (
    <div className="cm-text-block__content">
      <MBText.P className="cm-text-block__text" reset_spacing={false}>{children}</MBText.P>
    </div>
  );
};

export default TextBlock;
