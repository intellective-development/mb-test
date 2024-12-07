// @flow

import * as React from 'react';
import _ from 'lodash';
import classNames from 'classnames';
import { MBIcon, MBTextWithMatches } from '../../elements';
import { addressToOptionTextProps } from './utils';

type AddressDropdownProps = {|
  recent_addresses: Array<Object>,
  google_addresses: Array<Object>,
  input_address: string,
  visible: boolean,
  selected_index: number,
  submitOption: (number) => void
|};
const AddressDropdown = ({
  recent_addresses,
  google_addresses,
  input_address,
  visible,
  selected_index,
  submitOption
}: AddressDropdownProps) => {
  const container_class = classNames('cm-ae-dropdown__container', { open: visible });
  // NOTE: recent addresses always come after the user input option at index 0
  // so their index is offset by 1 to reflect that, likewise google addresses always
  // come after the user input and the recent addresses, so their index is offset
  // by 1 plus the number of recent addresses
  return (
    <div className={container_class}>
      <ul className="cm-ae-dropdown__list">
        {recent_addresses.map((address, index) => (
          <AddressOption
            recent
            key={address.local_id}
            submit={() => submitOption(index + 1)}
            selected={index + 1 === selected_index}
            {...addressToOptionTextProps(address, input_address)} />
        ))}
        {!_.isEmpty(google_addresses) && !_.isEmpty(recent_addresses) && <div className="cm-ae-dropdown__divider" /> }
        {google_addresses.map((ga, index) => (
          <AddressOption
            key={ga.id}
            submit={() => submitOption(index + 1 + recent_addresses.length)}
            selected={(1 + recent_addresses.length + index) === selected_index}
            main_text={ga.structured_formatting.main_text}
            main_text_matches={_.get(ga, 'structured_formatting.main_text_matched_substrings')}
            secondary_text={ga.structured_formatting.secondary_text}
            secondary_text_matches={_.get(ga, 'structured_formatting.secondary_text_matched_substrings')} />
        ))}
      </ul>
      {!_.isEmpty(google_addresses) &&
        <img
          srcSet="/assets/pbg@2x.png 2x,
                  /assets/pbg@3x.png 3x"
          src="/assets/pbg.png"
          className="cm-ae-dropdown__attribution"
          alt="powered by google" />
      }
    </div>
  );
};

type SubstringMatch = {length: number, offset: number};
type AddressOptionProps = {|
  main_text: string,
  secondary_text: string,
  main_text_matches: Array<SubstringMatch>,
  secondary_text_matches: Array<SubstringMatch>,
  recent?: boolean,
  selected: boolean,
  submit: (number) => void
|};
const AddressOption = ({
  main_text,
  secondary_text,
  main_text_matches,
  secondary_text_matches,
  recent = false,
  selected,
  submit
}: AddressOptionProps) => (
  <li className={classNames('cm-ae-dropdown__option', {selected})} onClick={submit}>
    <MBIcon name="clock" className={classNames('cm-ae-dropdown__option__icon', {visible: !!recent})} />
    <MBTextWithMatches className="cm-ae-dropdown__option__main" matches={main_text_matches} match_classname={'cm-ae-dropdown__option__match'}>
      {main_text}
    </MBTextWithMatches>
    <MBTextWithMatches className="cm-ae-dropdown__option__secondary" matches={secondary_text_matches} match_classname={'cm-ae-dropdown__option__match'}>
      {secondary_text}
    </MBTextWithMatches>
  </li>
);

export default AddressDropdown;
