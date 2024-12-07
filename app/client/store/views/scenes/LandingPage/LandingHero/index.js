// @flow

import * as React from 'react';
import bindClassNames from 'shared/utils/bind_classnames';
import I18n from 'store/localization';
import type { AddressRoutingOptions } from 'store/business/address';
import { FetchUserProcedure } from '../../../../../modules/user/user.dux';

import { MBAppStoreLink, MBLayout, MBLink, MBText } from '../../../elements';
import AddressExplanation from '../../../compounds/AddressExplanation';
import AgeTermsWarning from '../../../compounds/AgeTermsWarning';
import StoreEntry from '../../../compounds/StoreEntry';
import AccountInfo from './AccountInfo';
import styles from './index.scss';

const cn = bindClassNames(styles);

type Category = 'Wine' | 'Liquor' | 'Beer';
const CATEGORIES: Category[] = ['Wine', 'Liquor', 'Beer'];
const BACKGROUND_CHANGE_INTERVAL = 6000; // ms

type LandingHeroProps = {
  routing_options?: AddressRoutingOptions,
  show_address_entry_placeholder?: boolean,
  destination: string
};
type LandingHeroState = {display_category: Category};

class LandingHero extends React.Component<LandingHeroProps, LandingHeroState> {
  state = { display_category: CATEGORIES[0] }
  static defaultProps = { destination: '/store' }

  rotation_interval: ?number;

  componentDidMount(){
    FetchUserProcedure();
    this.rotation_interval = setInterval(this.rotateCategory, BACKGROUND_CHANGE_INTERVAL);
  }

  componentWillUnmount(){
    this.rotation_interval && clearInterval(this.rotation_interval);
  }

  rotateCategory = () => {
    this.setState(({display_category}) => {
      const current_category_index = CATEGORIES.indexOf(display_category);
      const next_category_index = (current_category_index + 1) % CATEGORIES.length;
      return {display_category: CATEGORIES[next_category_index]};
    });
  }

  render(){
    const { show_address_entry_placeholder, destination, routing_options } = this.props;
    const { display_category } = this.state;
    const [wine, liquor, beer] = CATEGORIES;

    return (
      <div className={styles.cmLandingHero}>
        <CategoryHero category_name={wine} active={display_category === wine} />
        <CategoryHero category_name={liquor} active={display_category === liquor} />
        <CategoryHero category_name={beer} active={display_category === beer} />
        <MBLayout.StandardGrid className={styles.cmLandingHero_ContentWrapper}>
          <div className={styles.cmLandingHero_PrimaryContent}>
            <MinibarLogo />
            <MBText.H1 className={styles.cmLandingHero_Tagline}>
              <CategoryText category_name={wine} active={display_category === wine} />{', '}
              <CategoryText category_name={liquor} active={display_category === liquor} />{', and '}
              <CategoryText category_name={beer} active={display_category === beer} />.<br />
              {I18n.t('ui.body.landing_hero.tagline')}
            </MBText.H1>
            <MBAppStoreLink className={styles.cmLandingHero_AppStoreLink} />
            <div className={styles.cmLandingHero_EntryWrapper}>
              <StoreEntry
                routing_options={routing_options}
                destination={destination}
                show_address_entry_placeholder={show_address_entry_placeholder} />
            </div>
            <AddressExplanation />
            <AgeTermsWarning className={styles.cmLandingHero_AgeTermsWarning} />
          </div>
          <AccountInfo />
        </MBLayout.StandardGrid>
      </div>
    );
  }
}

const MinibarLogo = () => (
  <MBLink.View
    id="logo"
    title="Minibar Delivery"
    href="/"
    className={styles.cmLandingHero_Logo}>
    <picture>
      <source
        media="(min-width: 768px)"
        height="140"
        width="140"
        alt="Minibar Delivery"
        srcSet={'/assets/components/scenes/LandingPage/minibar_logo_large.png, ' +
                '/assets/components/scenes/LandingPage/minibar_logo_large@2x.png 2x, ' +
                '/assets/components/scenes/LandingPage/minibar_logo_large@3x.png 3x'} />
      <source
        alt="Minibar Delivery"
        height="100"
        width="100"
        srcSet={'/assets/components/scenes/LandingPage/minibar_logo_small.png, ' +
                '/assets/components/scenes/LandingPage/minibar_logo_small@2x.png 2x, ' +
                '/assets/components/scenes/LandingPage/minibar_logo_small@3x.png 3x'} />
      <img
        alt="Minibar Delivery"
        src="/assets/components/scenes/LandingPage/minibar_logo_small.png" />
    </picture>
  </MBLink.View>
);

const CategoryHero = ({category_name, active}) => {
  return (
    <div
      className={cn(
        'cmLandingHero_CategoryHero',
        `cmLandingHero_CategoryHero__${category_name}`,
        {cmLandingHero_CategoryHero__Active: active}
      )} />
  );
};

const CategoryText = ({category_name, active}) => {
  return <MBText.Span className={cn('cmLandingHero_CategoryText', {cmLandingHero_CategoryText__Active: active})}>{category_name}</MBText.Span>;
};

export default LandingHero;
