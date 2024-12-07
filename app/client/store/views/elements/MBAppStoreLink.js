// @flow

import * as React from 'react';
import bindClassNames from '../../../shared/utils/bind_classnames';
import { isIOS, isAndroid } from '../../business/utils/is_mobile';

import MBLink from './MBLink';
import styles from './MBAppStoreLink.scss';

const cn = bindClassNames(styles);
const IOS_APP_STORE_LINK = 'https://itunes.apple.com/us/app/minibar-delivery-wine-liquor/id720850888?mt=8&uo=4&at=11l5XB&ct=minibar';
const PLAY_STORE_LINK = 'https://play.google.com/store/apps/details?id=minibar.android';

type MBAppStoreLinkProps = {className?: string};
const MBAppStoreLink = ({className}: MBAppStoreLinkProps) => {
  if (isIOS()) return <div className={cn('elMBAppStoreLink_Container', className)}><MBiOSAppStoreLink /></div>;
  if (isAndroid()) return <div className={cn('elMBAppStoreLink_Container', className)}><MBPlayStoreLink /></div>;

  // TODO: return fragment
  return (
    <div className={cn('elMBAppStoreLink_Container', className)}>
      <MBiOSAppStoreLink />
      <MBPlayStoreLink />
    </div>
  );
};

export const APP_STORE_LINK_ID = 'app-store-link';
const MBiOSAppStoreLink = () => (
  <MBLink.View id={APP_STORE_LINK_ID} href={IOS_APP_STORE_LINK} native_behavior target="_blank" rel="noopener noreferrer">
    <img
      alt="Download on the App Store"
      src={'/assets/components/elements/mb-app-store-link/ios-app-store.png'}
      srcSet={'/assets/components/elements/mb-app-store-link/ios-app-store@2x.png 2x, ' +
              '/assets/components/elements/mb-app-store-link/ios-app-store@3x.png 3x'} />
  </MBLink.View>
);

export const PLAY_STORE_LINK_ID = 'play-store-link';
const MBPlayStoreLink = () => (
  <MBLink.View id={PLAY_STORE_LINK_ID} href={PLAY_STORE_LINK} native_behavior target="_blank" rel="noopener noreferrer">
    <img
      alt="Get it on Google Play"
      src={'/assets/components/elements/mb-app-store-link/play-store.png'}
      srcSet={'/assets/components/elements/mb-app-store-link/play-store@2x.png 2x, ' +
              '/assets/components/elements/mb-app-store-link/play-store@3x.png 3x'} />
  </MBLink.View>
);

export default MBAppStoreLink;
