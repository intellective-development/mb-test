// @flow
import * as React from 'react';
import { MBGrid, MBLink, MBText } from '../elements';

type LinkListProps = {
  content: Array<{
    action_url: string,
    name: string
  }>
}

const LinkList = ({ content }: LinkListProps) => (
  <MBGrid className="cm-link-list" cols={1} medium_cols={2} large_cols={3}>
    {content.map(link => (
      <MBGrid.Element className="cm-link-list__link-container" key={link.name}>
        <MBLink.View href={link.action_url}>
          <MBText.Span className="cm-link-list__link">
            {link.name}
          </MBText.Span>
        </MBLink.View>
      </MBGrid.Element>
    ))}
  </MBGrid>
);

export default LinkList;
