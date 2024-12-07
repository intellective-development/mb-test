// @flow

export type TrackActionParams = {
  category?: string,
  action?: string,
  label?: string,
  value?: number
}

export const track = ({
  category = 'store',
  action = 'click',
  label = '',
  value = 0,
  ...other_values
}: TrackActionParams) => ({
  type: 'ANALYTICS:TRACK_EVENT',
  payload: { category, action, label, value, ...other_values}
});

export const trackPurchase = (order: Object): Action => ({
  type: 'ANALYTICS:TRACK_PURCHASE',
  payload: { order }
});
