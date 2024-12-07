import * as React from 'react';
import Rater from '../rater';

it('renders', () => {
  expect(render(
    <Rater />
  )).toMatchSnapshot();
});
