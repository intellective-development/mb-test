// @flow

import * as React from 'react';
import LinkList from '../LinkList';
import type { ContentModuleProps } from './index';

const LinkListModule = ({ content_module }: ContentModuleProps) => (<LinkList content={content_module.config.content} />);

export default LinkListModule;
