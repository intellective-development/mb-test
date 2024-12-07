// @flow

import * as React from 'react';
import classNames from 'classnames';
import I18n from 'store/localization';
import { product_list_constants, product_list_helpers } from 'store/business/product_list';

type SortDropdownProps = {
  selected_sort_option_id: product_list_constants.SortOptionId,
  show: boolean,
  selectSortOption(product_list_constants.SortOptionId): void
};
const SortDropdown = ({ selected_sort_option_id, show, selectSortOption }: SortDropdownProps) => {
  const container_classes = classNames('f-dropdown', 'dropdown-sort', {hidden: !show});

  return (
    <ul className={container_classes} >
      <li className="sort-option--descriptor">Sort Products:</li>
      {Object.keys(product_list_helpers.getVisibleSortOptions()).map(option_id => (
        <SortOption
          sort_option_id={option_id}
          selected={option_id === selected_sort_option_id}
          selectSortOption={selectSortOption}
          key={option_id} />
      ))}
    </ul>
  );
};

const SortOption = ({sort_option_id, selected, selectSortOption}) => {
  const handleClick = (e) => {
    e.preventDefault();
    selectSortOption(sort_option_id);
  };

  return (
    <li>
      <a
        href="#"
        onClick={handleClick}
        className={classNames('sort-option', {selected})}>
        {I18n.t(`ui.sort.${sort_option_id}`)}
      </a>
    </li>
  );
};

export default SortDropdown;
