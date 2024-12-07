
import * as React from 'react';

// import TestProvider from 'client/store/__tests__/utils/TestProvider';
import * as MBText from '../MBText';

// tests on the shared HOC behavior

describe('makeMBText', () => {
  const MBTextComponent = MBText.makeMBText('span');
  it('renders', () => {
    expect(MBTextComponent(<MBTextComponent />)).toMatchSnapshot();
  });
});

// tests on the individually exported components

describe('MBText.P', () => {
  it('renders', () => {
    expect(render(<MBText.P />)).toMatchSnapshot();
  });

  it('accepts the body_copy prop', () => {
    expect(render(<MBText.P body_copy />)).toMatchSnapshot();
  });
});

describe('MBText.Span', () => {
  it('renders', () => {
    expect(shallow(<MBText.Span />)).toMatchSnapshot();
  });
});

describe('MBText.H1', () => {
  it('renders', () => {
    expect(shallow(<MBText.H1 />)).toMatchSnapshot();
  });
});

describe('MBText.H2', () => {
  it('renders', () => {
    expect(shallow(<MBText.H2 />)).toMatchSnapshot();
  });
});

describe('MBText.H3', () => {
  it('renders', () => {
    expect(shallow(<MBText.H3 />)).toMatchSnapshot();
  });
});

describe('MBText.H4', () => {
  it('renders', () => {
    expect(shallow(<MBText.H4 />)).toMatchSnapshot();
  });
});

describe('MBText.H5', () => {
  it('renders', () => {
    expect(shallow(<MBText.H5 />)).toMatchSnapshot();
  });
});

describe('MBText.H6', () => {
  it('renders', () => {
    expect(shallow(<MBText.H6 />)).toMatchSnapshot();
  });
});

