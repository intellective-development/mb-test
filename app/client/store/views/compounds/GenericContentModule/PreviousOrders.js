// @flow

import * as React from 'react';
import PreviousOrders from '../PreviousOrders';
import type { ContentModuleProps } from './index';

const MBPreviousOrders = ({ content_module }: ContentModuleProps) => (
  <PreviousOrders {...content_module.config} />
);

export default MBPreviousOrders;
