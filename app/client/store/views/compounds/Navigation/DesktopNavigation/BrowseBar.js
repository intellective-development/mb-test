// @flow

import * as React from 'react';
import _, { sortBy } from 'lodash';
import bindClassNames from 'shared/utils/bind_classnames';
import type { ContentLayout } from 'store/business/content_layout';
import { content_module_helpers } from 'store/business/content_module';
import type { ListLink } from 'store/business/content_module';
import connectToObservables from 'shared/components/higher_order/connect_observables';
import locationStream from 'legacy_store/router/location_stream';

import { NAVIGATION_CATEGORY_DEFAULTS } from '../constants';
import withContentLayout from '../../../compounds/ContentLayout';
import SearchInput from './SearchInput';
import CategoryDropdown from './CategoryDropdown';
import { MBLink, withUniqueId } from '../../../elements';

import styles from './BrowseBar.scss';

const cn = bindClassNames(styles);

const NAVIGATION_CATEGORY_SECTION_ID = 'category_list';

type BrowseBarProps = {|
  show: boolean,
  location_fragment: string,
  content_layout: ContentLayout
|};
type BrowseBarState = {|
  selected_category_name: ?string,
  dropdown_open: boolean
|};

class BrowseBar extends React.Component<BrowseBarProps, BrowseBarState> {
  state = { selected_category_name: null, dropdown_open: false }

  componentWillReceiveProps(next_props: BrowseBarProps){
    if (this.props.location_fragment !== next_props.location_fragment){
      this.hideDropdown();
    }
  }

  showDropdown = (category_name: string) => {
    this.setState({selected_category_name: category_name, dropdown_open: true});
  }

  hideDropdown = () => {
    // only changing dropdown_open and not selected_category_name allows the dropdown to animate out
    this.setState({dropdown_open: false});
  }

  render(){
    const { content_layout } = this.props;
    const { selected_category_name, dropdown_open } = this.state;

    let category_links = NAVIGATION_CATEGORY_DEFAULTS;
    let selected_link = {};
    let dropdown_content_modules = [];
    if (content_layout){
      const content_module_sections = content_module_helpers.groupContentModulesBySection(content_layout.content);

      category_links = _.get(content_module_sections, `${NAVIGATION_CATEGORY_SECTION_ID}[0].config.links`) || [];
      category_links = sortBy(
        category_links,
        [
          ({ name }) =>
            ['Wine', 'Liquor', 'Beer', 'Mixers', 'Gifts'].indexOf(name)
        ]
      );
      selected_link = category_links.find(link => link.internal_name === selected_category_name) || {};
      dropdown_content_modules = content_module_sections[selected_link.dropdown_section_id] || [];
    }

    const dropdown_visible = dropdown_open && !!selected_category_name && !_.isEmpty(dropdown_content_modules);

    return (
      <nav className={styles.cmDBrowseBar}>
        <div onMouseLeave={this.hideDropdown}>
          <ul className={styles.cmDBrowseBar_CategoryList}>
            {category_links.map(link => (
              <CategoryElement
                key={link.internal_name}
                link={link}
                selected={(link.internal_name === selected_category_name) && dropdown_open}
                selectNavigationCategory={this.showDropdown} />
            ))}
          </ul>
          <CategoryDropdown
            is_available={!!(selected_link && selected_link.action_url)}
            selected_category_name={selected_category_name}
            content_modules={dropdown_content_modules}
            is_visible={dropdown_visible} />
        </div>
        <div className={styles.cmDBrowseBar_Search_Spacer} />
        <SearchInput />
      </nav>
    );
  }
}

type CategoryElementProps = {|
  link: ListLink,
  selected: boolean,
  selectNavigationCategory: (string) => void
|}
class CategoryElement extends React.Component<CategoryElementProps> {
  handleMouseEnter = () => {
    this.props.selectNavigationCategory(this.props.link.internal_name);
  }

  render(){
    const { link, selected } = this.props;
    const { name, action_url } = link;
    const disabled = !action_url;

    return (
      <li onMouseEnter={this.handleMouseEnter}>
        <MBLink.Text
          href={action_url}
          disabled={disabled}
          standard={false}
          className={cn('cmDBrowseBar_CategoryLink', {
            cmDBrowseBar_CategoryLink__Selected: selected,
            cmDBrowseBar_CategoryLink__Disabled: disabled
          })}>
          {name}
        </MBLink.Text>
      </li>
    );
  }
}

const BrowseBarContentLayout = withUniqueId('content_layout_id')(withContentLayout('Web_Navigation_Desktop_Category')(BrowseBar));
export default connectToObservables(BrowseBarContentLayout, {
  location_fragment: locationStream.map((location) => location.fragment)
});
export const __private__ = {
  BrowseBar
};

