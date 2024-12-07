// @flow

import * as React from 'react';
import AddonPlacement from 'cart/addon_placement';
import type { ContentLayout } from 'store/business/content_layout';
import { withUniqueId } from 'store/views/elements';
import withContentLayout from 'store/views/compounds/ContentLayout';
import GenericContentModule from 'store/views/compounds/GenericContentModule';

type ContentLayoutProps = {
  content_layout_id: string;
  content_layout: ContentLayout
};

// TODO think about making this override something passable as a prop to GenericContentLayout or GenericContentModule
const CartContentModule = ({ content_layout_id, module }) => {
  if (module.module_type === 'product_scroller'){
    return (
      <AddonPlacement
        content_layout_id={content_layout_id}
        content_module_id={module.id}
        product_ids={module.products}
        {...module.config} />
    );
  }

  return (
    <GenericContentModule
      content_layout_id={content_layout_id}
      content_module={module} />
  );
};

const CartContentLayout = ({ content_layout, content_layout_id }: ContentLayoutProps) => {
  if (!content_layout) return null;

  return (
    <div>
      {content_layout.content.filter((module) => !module.section_id).map(module => (
        <CartContentModule
          key={module.id}
          content_layout_id={content_layout_id}
          module={module} />
      ))}
    </div>
  );
};

export default withUniqueId('content_layout_id')(withContentLayout('Web_Cart_Content_Screen')(CartContentLayout));
