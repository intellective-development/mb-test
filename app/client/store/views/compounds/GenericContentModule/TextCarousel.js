// @flow

import * as React from 'react';
import { MBTextCarousel } from '../../elements';
import type { ContentModuleProps } from './index';

const MBTextCarouselModule = ({ content_module }: ContentModuleProps) => (<MBTextCarousel {...content_module.config} />);

export default MBTextCarouselModule;
