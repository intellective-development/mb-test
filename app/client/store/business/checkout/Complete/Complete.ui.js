import React from 'react';
/* eslint-disable-next-line import/no-extraneous-dependencies */
import { storiesOf } from '@storybook/react';

import { AccountCreated } from './OrderPanel/AccountCreated';
import { CreateButton } from './OrderPanel/CreateButton';
import { EmailLink } from './OrderPanel/EmailLink';
import { OrderPanel } from './OrderPanel/OrderPanel';
import { OrderPlaced } from './OrderPanel/OrderPlaced';
import { PasswordInput } from './OrderPanel/PasswordInput';
import { PhoneLink } from './OrderPanel/PhoneLink';
import { SaveTime } from './OrderPanel/SaveTime';

import { EmailButton } from './SharePanel/EmailButton';
import { FacebookButton } from './SharePanel/FacebookButton';
import { Give10Get10 } from './SharePanel/Give10Get10';
import { PromoCode } from './SharePanel/PromoCode';
import { SharePanel } from './SharePanel/SharePanel';
import { ShareWithFriends } from './SharePanel/ShareWithFriends';
import { TwitterButton } from './SharePanel/TwitterButton';

import { TryAppImage } from './TryAppPanel/TryAppImage';
import { TryAppPanel } from './TryAppPanel/TryAppPanel';
import { TryAppText } from './TryAppPanel/TryAppText';

storiesOf('components|Checkout/Complete/OrderPanel', module)
  .add('OrderPanel', () => <OrderPanel orderNum={141231231} />)
  .add('OrderPlaced', () => <OrderPlaced orderNum={141231231} />)
  .add('SaveTime', () => <SaveTime />)
  .add('AccountCreated', () => <AccountCreated />)
  .add('PasswordInput', () => <PasswordInput />)
  .add('CreateButton', () => <CreateButton />)
  .add('PhoneLink', () => <PhoneLink />)
  .add('EmailLink', () => <EmailLink />);

storiesOf('components|Checkout/Complete/SharePanel', module)
  .add('SharePanel', () => <SharePanel promoCode="PROMO123111" />)
  .add('ShareWithFriends', () => <ShareWithFriends />)
  .add('Give10Get10', () => <Give10Get10 />)
  .add('PromoCode', () => <PromoCode promoCode="PROMO123111" />)
  .add('TwitterButton', () => <TwitterButton />)
  .add('FacebookButton', () => <FacebookButton />)
  .add('EmailButton', () => <EmailButton />);

storiesOf('components|Checkout/Complete/TryAppPanel', module)
  .add('TryAppPanel', () => <TryAppPanel />)
  .add('TryAppImage', () => <TryAppImage />)
  .add('TryAppText', () => <TryAppText />);
