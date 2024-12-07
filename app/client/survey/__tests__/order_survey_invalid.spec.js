import * as React from 'react';
import OrderSurveyInvalid from '../order_survey_invalid';

it('renders', () => {
  expect(render(
    <OrderSurveyInvalid />
  )).toMatchSnapshot();
});
