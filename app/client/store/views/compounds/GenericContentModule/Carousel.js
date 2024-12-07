// @flow

import * as React from 'react';
import { MBCarousel } from '../../elements';
import type { ContentModuleProps } from './index';

const MBCarouselModule = ({ content_module }: ContentModuleProps) => (<MBCarousel {...content_module.config} />);

export default MBCarouselModule;
