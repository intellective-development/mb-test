import React from 'react';
import TestProvider from 'store/views/__tests__/utils/TestProvider';
import content_module_factory from 'store/business/content_module/__tests__/content_module.factory';
import CategoryDropdownContentModule, { __private__ } from '../CategoryDropdownContentModule';

const { groupProductTypeLinks } = __private__;

describe('CategoryDropdownContentModule', () => {
  it('renders a product_type_link_list', () => {
    const content_module = content_module_factory.build('product_type_link_list');

    expect(render(
      <CategoryDropdownContentModule content_module={content_module} />
    )).toMatchSnapshot();
  });

  it('renders a link_list', () => {
    const content_module = content_module_factory.build('link_list');

    expect(render(
      <CategoryDropdownContentModule content_module={content_module} />
    )).toMatchSnapshot();
  });

  it('renders a carousel', () => {
    const content_module = content_module_factory.build('carousel');

    expect(render(
      <TestProvider initial_state={{}}>
        <CategoryDropdownContentModule content_module={content_module} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});

describe('groupProductTypeLinks', () => {
  describe('with shop_all_link', () => {
    it('returns short lists as a single group, appending the shop_all_link', () => {
      const links = [
        {action_url: '1'},
        {action_url: '2'},
        {action_url: '3'},
        {action_url: '4'},
        {action_url: '5'}
      ];
      const all_link = {action_url: 'all'};

      expect(groupProductTypeLinks(links, all_link)).toEqual([[...links, all_link]]);
    });

    it('returns medium length lists as two shorter columns', () => {
      const links = [
        {action_url: '1'},
        {action_url: '2'},
        {action_url: '3'},
        {action_url: '4'},
        {action_url: '5'},
        {action_url: '6'}
      ];
      const all_link = {action_url: 'all'};

      expect(groupProductTypeLinks(links, all_link)).toEqual([
        links.slice(0, 4),
        [...links.slice(4), all_link]
      ]);
    });

    it('splits long lists into two columns', () => {
      const links = [
        {action_url: '1'},
        {action_url: '2'},
        {action_url: '3'},
        {action_url: '4'},
        {action_url: '5'},
        {action_url: '6'},
        {action_url: '7'},
        {action_url: '8'},
        {action_url: '9'},
        {action_url: '10'},
        {action_url: '11'},
        {action_url: '12'},
        {action_url: '13'}
      ];
      const all_link = {action_url: 'all'};

      expect(groupProductTypeLinks(links, all_link)).toEqual([
        links.slice(0, 7),
        [...links.slice(7), all_link]
      ]);
    });

    it('splits extremely long lists into two columns, truncating without losing the all_link', () => {
      const links = [
        {action_url: '1'},
        {action_url: '2'},
        {action_url: '3'},
        {action_url: '4'},
        {action_url: '5'},
        {action_url: '6'},
        {action_url: '7'},
        {action_url: '8'},
        {action_url: '9'},
        {action_url: '10'},
        {action_url: '11'},
        {action_url: '12'},
        {action_url: '13'},
        {action_url: '14'}
      ];
      const all_link = {action_url: 'all'};

      expect(groupProductTypeLinks(links, all_link)).toEqual([
        links.slice(0, 7),
        [...links.slice(7, 13), all_link]
      ]);
    });
  });

  describe('without shop_all_link', () => {
    it('returns short lists as a single group, appending the shop_all_link', () => {
      const links = [
        {action_url: '1'},
        {action_url: '2'},
        {action_url: '3'},
        {action_url: '4'},
        {action_url: '5'},
        {action_url: '6'}
      ];

      expect(groupProductTypeLinks(links)).toEqual([links]);
    });

    it('returns medium length lists as two shorter columns', () => {
      const links = [
        {action_url: '1'},
        {action_url: '2'},
        {action_url: '3'},
        {action_url: '4'},
        {action_url: '5'},
        {action_url: '6'},
        {action_url: '7'}
      ];

      expect(groupProductTypeLinks(links)).toEqual([
        links.slice(0, 4),
        links.slice(4)
      ]);
    });

    it('splits long lists into two columns', () => {
      const links = [
        {action_url: '1'},
        {action_url: '2'},
        {action_url: '3'},
        {action_url: '4'},
        {action_url: '5'},
        {action_url: '6'},
        {action_url: '7'},
        {action_url: '8'},
        {action_url: '9'},
        {action_url: '10'},
        {action_url: '11'},
        {action_url: '12'},
        {action_url: '13'},
        {action_url: '14'}
      ];

      expect(groupProductTypeLinks(links)).toEqual([
        links.slice(0, 7),
        links.slice(7)
      ]);
    });

    it('splits extremely long lists into two columns, truncating without losing the all_link', () => {
      const links = [
        {action_url: '1'},
        {action_url: '2'},
        {action_url: '3'},
        {action_url: '4'},
        {action_url: '5'},
        {action_url: '6'},
        {action_url: '7'},
        {action_url: '8'},
        {action_url: '9'},
        {action_url: '10'},
        {action_url: '11'},
        {action_url: '12'},
        {action_url: '13'},
        {action_url: '14'},
        {action_url: '15'}
      ];

      expect(groupProductTypeLinks(links)).toEqual([
        links.slice(0, 7),
        links.slice(7, 14)
      ]);
    });
  });
});
