// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import I18n from 'store/localization';
import classNames from 'classnames';
import { product_list_constants, product_list_actions } from 'store/business/product_list';

import { MBClickOutside, MBTouchable } from '../../../elements';
import SortDropdown from './SortDropdown';

type SortSelectorProps = {
  sort_option_id: product_list_constants.SortOptionId,
  product_list_id: string,

  // DTP
  setSort: typeof product_list_actions.setSort
};
type SortSelectorState = {
  show_dropdown: boolean
};
class SortSelector extends React.Component<SortSelectorProps, SortSelectorState> {
  state = {show_dropdown: false}

  selectSortOption = (next_sort_option_id) => {
    this.props.setSort(this.props.product_list_id, next_sort_option_id);
    this.closeDropdown();
  };

  closeDropdown = () => {
    this.setState({show_dropdown: false});
  };

  toggleDropdown = () => {
    this.setState({show_dropdown: !this.state.show_dropdown});
  };

  render(){
    const { sort_option_id } = this.props;
    const { show_dropdown } = this.state;

    return (
      <MBClickOutside handleClickOutside={this.closeDropdown} disableOnClickOutside={!show_dropdown}>
        <li className="facet facet--sort">
          <SortToggle
            open={show_dropdown}
            handleClick={this.toggleDropdown}
            sort_option_id={sort_option_id} />
          <SortDropdown
            selectSortOption={this.selectSortOption}
            selected_sort_option_id={sort_option_id}
            show={show_dropdown} />
        </li>
      </MBClickOutside>
    );
  }
}

const SortToggle = ({open, handleClick, sort_option_id}) => {
  const sort_description = I18n.t(`ui.sort.${sort_option_id}`);
  const link_classes = classNames('dropdown', 'dropdown-sort__toggle', {open: open});

  return (
    <div className="dropdown-sort__toggle__wrapper">
      <label className="dropdown-sort__toggle__label">Sort By:</label>
      <MBTouchable className={link_classes} onClick={handleClick}>{sort_description}</MBTouchable>
    </div>
  );
};

const SortSelectorDTP = { setSort: product_list_actions.setSort };
const SortSelectorContainer = connect(null, SortSelectorDTP)(SortSelector);

export default SortSelectorContainer;
