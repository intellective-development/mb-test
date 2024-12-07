// @flow
import _ from 'lodash';
import * as mb_cookie from 'store/business/utils/mb_cookie';

// This returns a boolean based on SR login state. We are assuming if the `sr_token` cookie is present then the user is logged in.
const hasShopRunnerToken = (): boolean => {
  return mb_cookie.isPresent('sr_token');
};

// SR content is inserted by their partner integration kit. Since their divs are not present on DOM ready we need to tell the PIK to render content.
const refreshShopRunnerContent = () => {
  if (window.Data.shoprunner && _.isFunction(window.sr_updateMessages)) window.sr_updateMessages();
};

export { hasShopRunnerToken, refreshShopRunnerContent };
