
import * as React from 'react';

// import TestProvider from 'src/views/__tests__/utils/TestProvider';
import MBButton from '../MBButton';

describe('MBButton', () => {
  it('renders hollow buttons', () => {
    expect(shallow(<MBButton type="hollow" />)).toMatchSnapshot();
  });

  it('renders small buttons', () => {
    expect(shallow(<MBButton size="small" />)).toMatchSnapshot();
  });

  it('renders large buttons', () => {
    expect(shallow(<MBButton size="large" />)).toMatchSnapshot();
  });

  it('renders buttons that expand', () => {
    expect(shallow(<MBButton expand />)).toMatchSnapshot();
  });

  it('renders with many props', () => {
    expect(shallow(<MBButton type="hollow" size="small" expand />)).toMatchSnapshot();
  });
});
