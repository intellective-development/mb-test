// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import { analytics_actions } from 'store/business/analytics';

type WithAnalyticsTrackingProps = {
  track: typeof analytics_actions.track,
  render: ({ trackPromotion: TrackPromotion }) => React.Node
};

const WithAnalyticsTracking = ({ render, track }: WithAnalyticsTrackingProps) => render({ track });

const WithAnalyticsTrackingDTP = { track: analytics_actions.track };

export default connect(null, WithAnalyticsTrackingDTP)(WithAnalyticsTracking);
