import * as React from 'react';
import {shallow} from 'enzyme';
import OrderSurveyFormFields from '../order_survey_form_fields';

const SURVEY = {
  id: 35,
  token: '-s2b0re4Vq12_umlmdkh0WiMEessPztm7oiOyruvWzc',
  score: null,
  comment: null,
  user_id: 1,
  order_id: 38,
  state: 'pending',
  created_at: '2017-03-02 14:46:07',
  updated_at: '2017-03-02 14:46:0'
};
const reasons = [
  { id: 3,
    name: 'Late Delivery',
    description: null,
    created_at: '2017-03-01 13:45:23',
    updated_at: '2017-03-01 13:45:23',
    active: true
  },
  { id: 4,
    name: 'Missing Item(s)',
    description: null,
    created_at: '2017-03-01 13:45:23',
    updated_at: '2017-03-01 13:45:23',
    active: true
  }
];

it('Updates state when reason is selected', () => {
  const component = shallow(
    <OrderSurveyFormFields survey={SURVEY} submitForm={null} />
  );
  const reasonClicked = component.instance().reasonClicked;
  expect(component.state('selected_reasons')).toHaveLength(0);
  reasonClicked(reasons[0]);
  expect(component.state('selected_reasons')).toHaveLength(1);
  reasonClicked(reasons[1]);
  expect(component.state('selected_reasons')).toHaveLength(2);
  reasonClicked(reasons[1]);
  expect(component.state('selected_reasons')).toHaveLength(1);
  reasonClicked(reasons[0]);
  expect(component.state('selected_reasons')).toHaveLength(0);
});
