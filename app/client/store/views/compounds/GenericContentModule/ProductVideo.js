
// @flow

import * as React from 'react';
import { MBProductVideo } from '../../elements';
import type { ContentModuleProps } from './index';

const ProductVideo = ({ content_module }: ContentModuleProps) => (<MBProductVideo {...content_module.config} />);

export default ProductVideo;
