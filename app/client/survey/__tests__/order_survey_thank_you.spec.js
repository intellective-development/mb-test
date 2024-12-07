import * as React from 'react';
import OrderSurveyThankYou from '../order_survey_thank_you';

it('renders', () => {
  expect(render(
    <OrderSurveyThankYou />
  )).toMatchSnapshot();
});
