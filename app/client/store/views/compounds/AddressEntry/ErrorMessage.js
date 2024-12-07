// @flow

import React from 'react';
import cn from 'classnames';
import i18n from 'store/localization';

type EntryMessageProps = {|message_type: 'no_address' | 'no_street' | 'not_found' | 'non_suggested_address'|};
const EntryMessage = ({message_type}: EntryMessageProps) => {
  const message = i18n.t(`ui.error.address_entry.${message_type}`, {defaults: [{scope: 'ui.error.address_entry.default'}]});

  return (
    <div className="cm-ae-error">
      <p className={cn('cm-ae-error__text', {'cm-ae-error__text--empty': !message_type})}>
        {message}
      </p>
    </div>
  );
};

export default EntryMessage;
