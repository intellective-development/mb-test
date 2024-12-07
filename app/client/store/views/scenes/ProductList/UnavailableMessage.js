// @flow

import * as React from 'react';
import I18n from 'store/localization';
import { MBLink } from '../../elements';

const UnavailableMessage = () => {
  const category_message = 'No products are available with the selected filters.';
  const header = category_message ? null : I18n.t('ui.product_list.unavailable.default_header');

  return (
    <div className="not-found">
      <h3 className="center subhead-2">{header}</h3>
      <p className="center p1 not-found__message">{category_message || I18n.t('ui.product_list.unavailable.default_body')}</p>
      <p className="center">
        <MBLink.View className="button" href="/store/">CONTINUE SHOPPING</MBLink.View>
      </p>
    </div>
  );
};

export default UnavailableMessage;
