import * as React from 'react';
import RaterStar from '../rater_star';

it('renders', () => {
  expect(render(
    <RaterStar />
  )).toMatchSnapshot();
});
