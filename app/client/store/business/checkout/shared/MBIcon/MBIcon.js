import { merge } from '@amory/style/umd/style';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

import ActivityIndicatorIcon from './ActivityIndicatorIcon';
import AmexIcon from './AmexIcon';
import AppStoreIcon from './AppStoreIcon';
import ArrowDownIcon from './ArrowDownIcon';
import ArrowUpIcon from './ArrowUpIcon';
import CancelIcon from './CancelIcon';
import CircleIcon from './CircleIcon';
import ClockIcon from './ClockIcon';
import CompletedIcon from './CompletedIcon';
import DateIcon from './DateIcon';
import DiscoverIcon from './DiscoverIcon';
import DoneIcon from './DoneIcon';
import EmailIcon from './EmailIcon';
import { EnjoyIcon } from './EnjoyIcon';
import FacebookIcon from './FacebookIcon';
import { MapPinIcon } from './MapPinIcon';
import MastercardIcon from './MastercardIcon';
import MinibarLogo from './MinibarLogo';
import PhoneIcon from './PhoneIcon';
import PlayStoreIcon from './PlayStoreIcon';
import ProductIcon from './ProductIcon';
import { QuoteIcon } from './QuoteIcon';
import SecureIcon from './SecureIcon';
import { ShopIcon } from './ShopIcon';
import StorefrontIcon from './StorefrontIcon';
import TwitterIcon from './TwitterIcon';
import VisaIcon from './VisaIcon';
import VisibilityIcon from './VisibilityIcon';

const Icons = {
  amex: AmexIcon,
  appStore: AppStoreIcon,
  arrowDown: ArrowDownIcon,
  arrowUp: ArrowUpIcon,
  cancel: CancelIcon,
  circle: CircleIcon,
  clock: ClockIcon,
  completed: CompletedIcon,
  date: DateIcon,
  discover: DiscoverIcon,
  done: DoneIcon,
  email: EmailIcon,
  enjoy: EnjoyIcon,
  facebook: FacebookIcon,
  logo: MinibarLogo,
  mastercard: MastercardIcon,
  mapPin: MapPinIcon,
  phone: PhoneIcon,
  playStore: PlayStoreIcon,
  product: ProductIcon,
  quote: QuoteIcon,
  secure: SecureIcon,
  shop: ShopIcon,
  storefront: StorefrontIcon,
  twitter: TwitterIcon,
  visa: VisaIcon,
  visibility: VisibilityIcon,
  wait: ActivityIndicatorIcon
};

const onHover = ['clear', 'facebook', 'instagram', 'twitter'];

const MBIcon = ({
  name = 'circle',
  selector = '::before',
  style = {},
  ...props
}) => {
  const Icon = Icons[name] || Icons.circle;

  return merge({
    [selector]: {
      backgroundImage:
        `url("data:image/svg+xml,${encodeURIComponent(
          renderToStaticMarkup(<Icon {...props} />)
        )
          .replace(/%[\dA-F]{2}/gu, (match) => {
            switch (match){
              case '%20': return ' ';
              case '%3D': return '=';
              case '%3A': return ':';
              case '%2F': return '/';
              default: return match.toLowerCase();
            }
          })
        }"
      )`,
      backgroundRepeat: 'no-repeat',
      content: "' '",
      display: 'inline-block',
      minHeight: 16,
      minWidth: 16,
      ...style
    }
  },
  onHover.includes(name)
    ? {
      [`:hover${selector}`]: {
        backgroundImage: `url("data:image/svg+xml,${
          encodeURIComponent(
            renderToStaticMarkup(<Icon active {...props} />)
          )
            .replace(/%[\dA-F]{2}/gu, (match) => {
              switch (match){
                case '%20': return ' ';
                case '%3D': return '=';
                case '%3A': return ':';
                case '%2F': return '/';
                default: return match.toLowerCase();
              }
            })
        }")`
      }
    } : {});
};

export default MBIcon;
