
import React from 'react';
import uuid from 'uuid';
import withUniqueId from '../WithUniqueId';

jest.mock('uuid');

describe('WithUniqueId', () => {
  it('renders', () => {
    uuid.mockReturnValue('abc123');
    const WrappedComponent = withUniqueId('my_id')(({my_id}) => (
      <div>{my_id}</div>
    ));

    expect(shallow(
      <WrappedComponent />
    )).toMatchSnapshot();
  });
});
