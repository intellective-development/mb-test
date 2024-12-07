
import * as React from 'react';

// import TestProvider from 'client/store/__tests__/utils/TestProvider';
import * as MBModal from '../MBModal';

describe('MBModal.Modal', () => {
  it('renders', () => {
    expect(shallow(
      <MBModal.Modal >
        <div>My Content!</div>
      </MBModal.Modal>
    )).toMatchSnapshot();
  });

  it('renders with a header in its content', () => {
    expect(shallow(
      <MBModal.Modal >
        <MBModal.SectionHeader>
          Look at this modal
        </MBModal.SectionHeader>
        <div>My Content!</div>
      </MBModal.Modal>
    )).toMatchSnapshot();
  });
});

describe('MBModal.SectionHeader', () => {
  it('renders', () => {
    expect(shallow(
      <MBModal.SectionHeader>
        Look at this modal
      </MBModal.SectionHeader>
    )).toMatchSnapshot();
  });

  it('renders with the left and right props specified', () => {
    expect(shallow(
      <MBModal.SectionHeader
        renderLeft={() => <MBModal.Back onClick={() => console.info('back!')} />}
        renderRight={() => <MBModal.Close onClick={() => console.info('close!')} />} >
        Look at this modal
      </MBModal.SectionHeader>
    )).toMatchSnapshot();
  });
});

describe('MBModal.Back', () => {
  it('renders', () => {
    expect(shallow(
      <MBModal.Back onClick={() => console.info('back!')} />
    )).toMatchSnapshot();
  });
});

describe('MBModal.Close', () => {
  it('renders', () => {
    expect(shallow(
      <MBModal.Close onClick={() => console.info('close!')} />
    )).toMatchSnapshot();
  });
});
