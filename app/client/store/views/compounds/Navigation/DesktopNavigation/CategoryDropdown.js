// @flow

import * as React from 'react';
import i18n from 'store/localization';
import _ from 'lodash';
import bindClassNames from 'shared/utils/bind_classnames';
import type { ContentModule } from 'store/business/content_module';

import CategoryDropdownContentModule, { CategoryDropdownContentModuleDivider } from './CategoryDropdownContentModule';
import { MBLayout, MBText } from '../../../elements';
import styles from './CategoryDropdown.scss';

const cn = bindClassNames(styles);

type NavigationDropdownProps = {
  content_modules: ContentModule[],
  selected_category_name: ?string,
  is_visible: boolean,
  is_available: boolean
}

class NavigationDropdown extends React.Component<NavigationDropdownProps> {
  renderDropdownElement(){
    const { is_available, selected_category_name, content_modules } = this.props;

    if (selected_category_name && !is_available){
      return <NavigationDropdownCategoryUnavailable category_name={selected_category_name} />;
    } else if (selected_category_name && !_.isEmpty(content_modules)){
      return <NavigationDropdownContentLayout content_modules={content_modules} />;
    } else {
      return null;
    }
  }

  render(){
    const { is_visible } = this.props;

    return (
      <div className={cn('cmDCategoryDropdown_Wrapper', {cmDCategoryDropdown_Wrapper__Open: is_visible})}>
        <div className={cn('cmDCategoryDropdown_Dropdown', {cmDCategoryDropdown__Dropdown_Open: is_visible})}>
          {this.renderDropdownElement()}
        </div>
      </div>
    );
  }
}

const NavigationDropdownCategoryUnavailable = ({category_name}) => {
  const unavailable_message = i18n.t(`ui.body.navigation.category_dropdown.${category_name}`);

  return (
    <MBText.P className={styles.cmDCategoryDropdown_UnavailableMessage}>{unavailable_message}</MBText.P>
  );
};

const NavigationDropdownContentLayout = ({content_modules}) => {
  const content = _.flatMap(content_modules, (content_module) => ([
    <CategoryDropdownContentModuleDivider
      module_type={content_module.module_type}
      key={`divider_${content_module.internal_name}`} />,
    <CategoryDropdownContentModule
      content_module={content_module}
      key={content_module.internal_name} />
  ]));

  return <MBLayout.StandardGrid no_padding className={styles.cmDCategoryDropdown_AvailableContainer}>{content}</MBLayout.StandardGrid>;
};

export default NavigationDropdown;
