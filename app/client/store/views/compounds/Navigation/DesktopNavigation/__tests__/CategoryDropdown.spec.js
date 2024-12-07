
import React from 'react';
import content_module_factory from 'store/business/content_module/__tests__/content_module.factory';

// import TestProvider from 'store/views/__tests__/utils/TestProvider';
import CategoryDropdown from '../CategoryDropdown';

describe('CategoryDropdown', () => {
  it('renders', () => {
    const content_modules = [
      content_module_factory.build('product_type_link_list'),
      content_module_factory.build('link_list'),
      content_module_factory.build('carousel')
    ];

    expect(shallow(<CategoryDropdown content_modules={content_modules} />)).toMatchSnapshot();
  });
});
