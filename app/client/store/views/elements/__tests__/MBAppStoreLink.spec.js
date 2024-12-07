
import React from 'react';

import { isIOS, isAndroid, __clearMocks__ } from 'store/business/utils/is_mobile';
import MBAppStoreLink from '../MBAppStoreLink';

jest.mock('store/business/utils/is_mobile');

describe('MBAppStoreLink', () => {
  afterEach(() => {
    __clearMocks__();
  });

  it('renders an app store button if the userAgent matches ios', () => {
    isIOS.mockReturnValue(true);
    isAndroid.mockReturnValue(false);

    expect(render(
      <MBAppStoreLink />
    )).toMatchSnapshot();
  });

  it('renders a google play store button if the userAgent matches android', () => {
    isIOS.mockReturnValue(false);
    isAndroid.mockReturnValue(true);

    expect(render(
      <MBAppStoreLink />
    )).toMatchSnapshot();
  });

  it('renders both if platform can not be determined by userAgent', () => {
    isIOS.mockReturnValue(false);
    isAndroid.mockReturnValue(false);

    expect(render(
      <MBAppStoreLink />
    )).toMatchSnapshot();
  });
});
