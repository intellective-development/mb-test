// @flow

import * as React from 'react';
import _ from 'lodash';
import bindClassNames from '../../../shared/utils/bind_classnames';
import MBCard from './MBCard';
import styles from './MBCardCarousel.scss';
import { MBDynamicIcon, MBLayout, MBText, MBHeader } from './index';

const cn = bindClassNames(styles);

const LARGE_MIN_WIDTH = 1024;
const MEDIUM_MIN_WIDTH = 768;

type WindowSize = 'small' | 'medium' | 'large';

type MBCardCarouselProps<T> = {
  cards: T[],
  selectKey: (props: T) => string | number,
  selectTitle: (props: T) => string | number,
  renderCard: (props: T) => Array<React.Element<typeof MBCard>>
}

type MBCardCarouselState = {
  page: number,
  window_size: WindowSize
}

const CARDS_PER_PAGE: { [size: WindowSize]: number } = {
  small: 1,
  medium: 2,
  large: 3
};

const getWindowSize = (): WindowSize => {
  const window_width = window.innerWidth;

  if (window_width >= LARGE_MIN_WIDTH){
    return 'large';
  }

  if (window_width >= MEDIUM_MIN_WIDTH){
    return 'medium';
  }

  return 'small';
};

const nullFn = () => null;

export default class MBCardCarousel extends React.Component<MBCardCarouselProps, MBCardCarouselState> {
  constructor(props){
    super(props);

    this.state = { page: 0, window_size: getWindowSize() };
  }

  componentDidMount(){ window.addEventListener('resize', this.updateWindowSize); }
  componentWillUnmount(){ window.removeEventListener('resize', this.updateWindowSize); }

  updateWindowSize = () => this.setState(({ window_size: prev_window_size }) => {
    const window_size = getWindowSize();
    if (window_size === prev_window_size){ return null; }
    return { window_size, page: 0 };
  });

  incrementPageNumber = () => this.setState(({ page }) => ({ page: page + 1 }));
  decrementPageNumber = () => this.setState(({ page }) => ({ page: page - 1 }));

  render(){
    const { cards, selectKey, selectTitle, renderCard } = this.props;
    const { page, window_size } = this.state;
    const pages = _.chunk(cards, CARDS_PER_PAGE[window_size]);
    const can_increment = page < pages.length - 1;
    const can_decrement = page > 0;
    const current_cards = pages[page];

    if (_.isEmpty(current_cards)){
      return null;
    }

    const left_arrow = (
      <div
        className={cn('elMBCardCarousel__Arrow elMBCardCarousel__Arrow--Left', { 'elMBCardCarousel__Arrow--Disabled': !can_decrement })}
        onClick={can_decrement ? this.decrementPageNumber : nullFn}>
        <MBDynamicIcon name="chevron_left" width={36} height={36} />
      </div>
    );

    const right_arrow = (
      <div
        className={cn('elMBCardCarousel__Arrow elMBCardCarousel__Arrow--Right', { 'elMBCardCarousel__Arrow--Disabled': !can_increment })}
        onClick={can_increment ? this.incrementPageNumber : nullFn}>
        <MBDynamicIcon name="chevron_right" width={36} height={36} />
      </div>
    );

    return (
      <MBLayout.StandardGrid>
        <div className={cn('elMBCardCarousel')}>
          <MBHeader
            title={'Recent Orders'}
            action_name={'See order history'}
            action_url={'/account/orders'}
            native_behavior />
          {left_arrow}
          {right_arrow}
          <div className={cn('elMBCardCarousel__Cards')}>
            <div className={cn('elMBCardCarousel__CardTitle')}>
              {left_arrow}
              <MBText.Span>
                {selectTitle(current_cards[0])}
              </MBText.Span>
              {right_arrow}
            </div>
            {current_cards.map(card_props => (
              <React.Fragment key={selectKey(card_props)}>
                {renderCard(card_props)}
              </React.Fragment>
            ))}
          </div>
        </div>
      </MBLayout.StandardGrid>
    );
  }
}
