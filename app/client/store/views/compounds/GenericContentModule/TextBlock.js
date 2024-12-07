// @flow

import * as React from 'react';
import TextBlock from '../TextBlock';
import type { ContentModuleProps } from './index';

const MBTextModule = ({ content_module }: ContentModuleProps) => (
  <TextBlock>
    {content_module.config.body}
  </TextBlock>
);

export default MBTextModule;
