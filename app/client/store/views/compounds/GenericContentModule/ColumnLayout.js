// @flow

import * as React from 'react';
import ColumnLayout from '../ColumnLayout';
import type { ContentModuleProps } from './index';

type ColumnLayoutConfig = {
  column_section_ids: string[],
}

type ColumnLayoutProps = {
  ...ContentModuleProps,
  content_layout_id: string,
  config: ColumnLayoutConfig
}

const ColumnLayoutModule = ({ content_layout_id, content_module }: ColumnLayoutProps) => (
  <ColumnLayout content_layout_id={content_layout_id} {...content_module.config} />
);

export default ColumnLayoutModule;
