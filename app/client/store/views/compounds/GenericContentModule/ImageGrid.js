// @flow

import * as React from 'react';
import { MBImageGrid } from '../../elements';
import type { ContentModuleProps } from './index';
import type { ImageGridProps } from '../../elements';

type ImageGridModuleProps = {
  ...ContentModuleProps,
  config: ImageGridProps
}

const ImageGridModule = ({ content_module }: ImageGridModuleProps) => (<MBImageGrid {...content_module.config} />);

export default ImageGridModule;
