
// @flow

import * as React from 'react';
import BrandDescription from '../BrandDescription';
import type { ContentModuleProps } from './index';

const BrandDescriptionModule = ({ content_module }: ContentModuleProps) => (<BrandDescription brand={content_module.config.brand} />);

export default BrandDescriptionModule;
