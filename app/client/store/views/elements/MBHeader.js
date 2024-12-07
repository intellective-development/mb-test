// @flow
import * as React from 'react';
import MBLink from './MBLink';

type MBHeaderProps = { title: string, action_name?: string, action_url?: string, native_behavior?: boolean };
export const MBHeader = ({ title, action_name, action_url, native_behavior }: MBHeaderProps) => (
  <h2 className="heading-row heading-row--has-subheader">
    {title}
    {action_url && (
      <MBLink.Text native_behavior={native_behavior} href={action_url} className="heading-row__subheader">
        {action_name} »
      </MBLink.Text>
    )}
  </h2>
);

export default MBHeader;
