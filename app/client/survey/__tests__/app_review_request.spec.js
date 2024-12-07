import * as React from 'react';
import AppReviewRequest from '../app_review_request';

describe('AppReviewRequest', () => {
  it('renders a request when the score prop is 5', () => {
    expect(render(
      <AppReviewRequest score={5} />
    )).toMatchSnapshot();
  });

  it('renders null when the score prop is less than five', () => {
    expect(render(
      <AppReviewRequest score={4} />
    )).toMatchSnapshot();
  });
});
