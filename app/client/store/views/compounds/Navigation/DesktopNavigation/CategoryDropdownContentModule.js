// @flow

import React from 'react';
import bindClassNames from 'shared/utils/bind_classnames';
import type { ContentModule, LinkList, ProductTypeLinkList, ContentModuleCarousel } from 'store/business/content_module';

import { MBLink, MBText } from '../../../elements';
import WithPromotionTracking from '../../WithPromotionTracking';
import styles from './CategoryDropdown.scss';

const cn = bindClassNames(styles);

type CategoryDropdownContentModuleProps = {content_module: ContentModule};
const CategoryDropdownContentModule = ({content_module}: CategoryDropdownContentModuleProps) => { // TODO: pureUpdate?
  switch (content_module.module_type){
    case 'link_list':
    case 'product_type_link_list':
      return <ProductTypeLinkListModule {...content_module} />;
    case 'carousel':
      return <CarouselModule {...content_module} />;
    default:
      return null;
  }
};

type ProductTypeLinkListModuleProps = LinkList | ProductTypeLinkList;
const ProductTypeLinkListModule = ({config}: ProductTypeLinkListModuleProps) => {
  const { content, shop_all_link } = config;

  // ideally we'd do this without the chunking, but percentage width based grids
  // don't work well when inside a horizontal flex container,
  // as the overall width can't be determined by the width of each row.
  const col_groups = groupProductTypeLinks(content, shop_all_link);

  return (
    <div className={cn('cmDCategoryDropdown_ContentModule', 'cmDCategoryDropdown_LinkList_Container')}>
      <MBText.H3 className={styles.cmDCategoryDropdown_LinkList_Title}>{config.title}</MBText.H3>
      <div className={styles.cmDCategoryDropdown_LinkList_ColGroup}>
        {col_groups.map(col_links => (
          <ul className={styles.cmDCategoryDropdown_LinkList_Col} key={col_links[0].internal_name}>
            {col_links.map(link => (
              <li key={link.internal_name}>
                <MBLink.Text
                  href={link.action_url}
                  className={cn('cmDCategoryDropdown_LinkList_ElLink', {cmDCategoryDropdown_LinkList_ElLink__ShopAll: link === shop_all_link})}
                  native_behavior={link.native_behavior}
                  standard={false}>
                  {link.name && link.name.toLowerCase() === 'cbd' ? 'CBD' : link.name}
                </MBLink.Text>
              </li>
            ))}
          </ul>
        ))}
      </div>
    </div>
  );
};

type CarouselModuleProps = ContentModuleCarousel;
const CarouselModule = ({config}: CarouselModuleProps) => {
  const [banner] = config.content;

  if (!banner) return null;

  return (
    <WithPromotionTracking render={({ trackPromotion }) => (
      <MBLink.View
        href={banner.action_url}
        className={cn('cmDCategoryDropdown_ContentModule', 'cmDCategoryDropdown_Carousel')}
        beforeNavigate={() => trackPromotion(banner.name, 'category-dropdown')}>
        <img
          src={banner.image_url}
          width={banner.image_width}
          height={banner.image_height}
          alt={banner.name} />
      </MBLink.View>
    )} />
  );
};

export default CategoryDropdownContentModule;

export const CategoryDropdownContentModuleDivider = () => {
  return (
    <div className={styles.cmDCategoryDropdown_Divider}>
      <div className={styles.cmDCategoryDropdown_DividerLine} />
    </div>
  );
};

// helpers

const SINGLE_COL_LIST_MAX = 6;
const LIST_MAX = 14;
const groupProductTypeLinks = <T: Object>(links: T[], shop_all_link?: T): T[][] => {
  let resized_links;
  if (shop_all_link){
    // we cap the length of the link list just shy of the max and append shop_all, ensuring it's always the last element
    resized_links = [...links.slice(0, LIST_MAX - 1), shop_all_link];
  } else {
    // otherwise, we simply cap it at the max
    resized_links = links.slice(0, LIST_MAX);
  }

  // for short lists, we return a single column
  if (resized_links.length <= SINGLE_COL_LIST_MAX) return [resized_links];

  // for longer lists, we split into two columns of near-equal length
  // ceil ensures the middle element for odd lists is grouped into the first column
  const middle_point = Math.ceil((resized_links.length) / 2);

  return [
    resized_links.slice(0, middle_point),
    resized_links.slice(middle_point)
  ];
};

export const __private__ = {
  groupProductTypeLinks
};
