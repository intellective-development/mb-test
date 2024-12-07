// @flow
import * as React from 'react';
import _ from 'lodash';
import bindClassNames from 'shared/utils/bind_classnames';
import type { ContentLayout } from 'store/business/content_layout';
import type { ImageContent } from 'store/business/content_module';
import { NAVIGATION_CATEGORY_DEFAULTS } from '../constants';

import withContentLayout from '../../../compounds/ContentLayout';
import { MBLink, MBText, withUniqueId } from '../../../elements';
import styles from './CategoryDropdown.scss';

const cn = bindClassNames(styles);

type CategoryDropdownProps = {|
  is_showing: boolean,
  content_layout: ContentLayout
|};
export const CategoryDropdown = ({is_showing, content_layout}: CategoryDropdownProps) => {
  let category_links = NAVIGATION_CATEGORY_DEFAULTS;
  if (content_layout){
    // we assume that this content layout will only have one element, which contains the desired links
    category_links = _.get(content_layout, 'content[0].config.links');
  }

  return (
    <div className={cn('cmMCategoryDropdown_Wrapper', {cmMCategoryDropdown_Wrapper__DropdownVisible: is_showing})}>
      <ul className={cn('cmMCategoryDropdown', {cmMCategoryDropdown__Visible: is_showing})}>
        {category_links.map(el => (
          <CategoryElement
            key={el.name}
            name={el.name}
            icon_banner={el.icon_banner}
            action_url={el.action_url}
            disabled={!el.action_url} />
        ))}
      </ul>
    </div>
  );
};

type CategoryElementProps = {|
  action_url: string,
  name: 'wine' | 'beer' | 'liquor' | 'mixers' | 'gifts',
  icon_banner?: ImageContent,
  disabled?: boolean
|};
const CategoryElement = ({ action_url, name, icon_banner, disabled }: CategoryElementProps) => {
  return (
    <li>
      <MBLink.View
        disabled={disabled}
        className={cn('cmMCategoryDropdown_Element', {cmMCategoryDropdown_Element__Disabled: disabled})}
        href={action_url}>
        <CategoryElementIcon category_name={name} icon_banner={icon_banner} />
        <MBText.Span className={styles.cmMCategoryDropdown_ElementName}>{name}</MBText.Span>
        {disabled && <MBText.Span className={styles.cmMCategoryDropdown_UnavailableMessage}>&ensp;(not available)</MBText.Span>}
      </MBLink.View>
    </li>
  );
};

const CategoryElementIcon = ({category_name, icon_banner}) => {
  if (!icon_banner) return null;

  return (
    <img
      className={styles.cmMCategoryDropdown_ElementIcon}
      alt={category_name}
      src={icon_banner.image_url}
      height={icon_banner.image_height}
      width={icon_banner.image_width} />
  );
};

export default withUniqueId('content_layout_id')(withContentLayout('Web_Navigation_Mobile_Category')(CategoryDropdown));
