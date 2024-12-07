
import React from 'react';
import content_layout_factory from 'store/business/content_layout/__tests__/content_layout.factory';
import content_module_factory from 'store/business/content_module/__tests__/content_module.factory';
import TestProvider from 'store/views/__tests__/utils/TestProvider';

import { __private__ } from '../BrowseBar';

const { BrowseBar } = __private__;

describe('BrowseBar', () => {
  it('renders', () => {
    const content_layout = content_layout_factory.build({
      content: [
        content_module_factory.build('navigation_category', {section_id: 'category_list'}),
        content_module_factory.build('product_type_link_list', {section_id: 'wine_dropdown'})
      ]
    });

    expect(render(
      <TestProvider initial_state={{}}>
        <BrowseBar content_layout={content_layout} />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders default content', () => {
    expect(shallow(
      <BrowseBar />
    )).toMatchSnapshot();
  });
});
