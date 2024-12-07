// @flow

import * as React from 'react';
import type { ContentLayout } from 'store/business/content_layout';

import { withUniqueId } from '../../elements';
import withContentLayout, { ContentLayoutLoader } from '../../compounds/ContentLayout';
import ContentModule from '../../compounds/GenericContentModule';

type ContentLayoutProps = {
  wrapper_class_name?: string,
  content_layout_id: string;
  content_layout: ContentLayout;
  content_layout_request_status: boolean;
  suppress_loading: boolean;
};

const ContentLayoutComponent = ({ content_layout, content_layout_id, content_layout_request_status, suppress_loading, wrapper_class_name }: ContentLayoutProps) => {
  const hide_loader = suppress_loading || content_layout_request_status === 'SUCCESS';

  if (!hide_loader) return (<ContentLayoutLoader />);
  if (!content_layout) return null;

  return (
    <div className={wrapper_class_name}>
      {content_layout.content.filter((content_module) => !content_module.section_id).map((content_module) => (
        <ContentModule
          key={content_module.id}
          content_layout_id={content_layout_id}
          content_module={content_module} />
      ))}
    </div>
  );
};

export default (content_layout_name: string) => (
  withUniqueId('content_layout_id')(withContentLayout(content_layout_name)(ContentLayoutComponent))
);
