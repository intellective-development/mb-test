// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import { analytics_actions } from '../../business/analytics';

type TrackPromotion = (promotion_name: string, location: string) => void;
type WithPromotionTrackingProps = {
  trackPromotion: TrackPromotion,
  render: ({ trackPromotion: TrackPromotion }) => React.Node
};

const WithPromotionTracking = ({ render, trackPromotion }: WithPromotionTrackingProps) => render({ trackPromotion });

const WithPromotionTrackingDTP = {
  trackPromotion: (promotion: string, location: string) => analytics_actions.track({
    category: 'promotion',
    action: _.kebabCase(promotion),
    label: _.kebabCase(location)
  })
};

export default connect(null, WithPromotionTrackingDTP)(WithPromotionTracking);
