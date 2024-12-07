
import React from 'react';
import content_layout_factory from 'store/business/content_layout/__tests__/content_layout.factory';
import content_module_factory from 'store/business/content_module/__tests__/content_module.factory';

import { CategoryDropdown } from '../CategoryDropdown';

describe('CategoryDropdown', () => {
  it('renders', () => {
    const content_layout = content_layout_factory.build({
      content: [
        content_module_factory.build('navigation_category')
      ]
    });

    expect(render(
      <CategoryDropdown content_layout={content_layout} />
    )).toMatchSnapshot();
  });

  it('renders default content', () => {
    expect(shallow(
      <CategoryDropdown />
    )).toMatchSnapshot();
  });
});
