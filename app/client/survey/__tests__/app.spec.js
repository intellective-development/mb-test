import * as React from 'react';
import { shallow } from 'enzyme';
import App from '../app';

const survey = {id: 35, token: '-s2b0re4Vq12_umlmdkh0WiMEessPztm7oiOyruvWzc', score: null, comment: null, user_id: 1, order_id: 38, state: 'pending', created_at: '2017-03-02 14:46:07', updated_at: '2017-03-02 14:46:07'};
const referral_code = 'abc123';

it('renders', () => {
  const component = shallow(<App survey={survey} referralCode={referral_code} />);
  expect(component).toMatchSnapshot();
});
