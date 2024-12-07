// @flow
import * as React from 'react';
import bindClassNames from 'shared/utils/bind_classnames';
import connectToObservables from 'shared/components/higher_order/connect_observables';
import locationStream from 'legacy_store/router/location_stream';


import { MBClickOutside, MBDynamicIcon, MBIcon, MBInput, MBText, MBTouchable } from '../../../elements';
import Search from '../shared/Search';
import CategoryDropdown from './CategoryDropdown';
import styles from './BrowseBar.scss';

const cn = bindClassNames(styles);

type BrowseBarProps = {|
  location_fragment: string
|};
type BrowseBarState = {|
  search_active: boolean,
  category_dropdown_open: boolean
|};
class BrowseBar extends React.Component<BrowseBarProps, BrowseBarState> {
  state = {search_active: false, category_dropdown_open: false}

  componentWillReceiveProps(next_props: BrowseBarProps){
    if (this.props.location_fragment !== next_props.location_fragment){
      this.hideCategoryDropdown();
    }
  }

  openSearch = () => {
    this.setState({search_active: true});
  }

  closeSearch = () => {
    this.setState({search_active: false});
  }

  toggleCategoryDropdown = () => {
    this.setState(prev_state => ({category_dropdown_open: !prev_state.category_dropdown_open}));
  }

  hideCategoryDropdown = () => {
    this.setState({category_dropdown_open: false});
  }

  render(){
    const { search_active, category_dropdown_open } = this.state;

    return (
      <nav className={styles.cmMBrowseBar}>
        <Categories
          search_active={search_active}
          category_dropdown_open={category_dropdown_open}
          toggleCategoryDropdown={this.toggleCategoryDropdown}
          hideCategoryDropdown={this.hideCategoryDropdown} />
        <SearchInput
          openSearch={this.openSearch}
          closeSearch={this.closeSearch}
          search_active={search_active} />
      </nav>
    );
  }
}

const Categories = ({search_active, category_dropdown_open, toggleCategoryDropdown, hideCategoryDropdown}) => {
  return (
    <MBClickOutside handleClickOutside={hideCategoryDropdown} disableOnClickOutside={!category_dropdown_open}>
      <div className={cn('cmMBrowseBar_LeftWrapper', {cmMBrowseBar_LeftWrapper__SearchActive: search_active})}>
        <MBTouchable
          className={cn('cmMBrowseBar_Left', {cmMBrowseBar_Left__Active: category_dropdown_open})}
          onClick={toggleCategoryDropdown}>
          <MBText.Span className={styles.cmMBrowseBar_CategoryPrompt} >Categories</MBText.Span>
          <MBIcon name="down_arrow_red" className={cn('cmMBrowseBar_DicloseIcon', {cmMBrowseBar_DicloseIcon__Active: category_dropdown_open})} />
        </MBTouchable>
        <CategoryDropdown is_showing={category_dropdown_open} hide={hideCategoryDropdown} />
      </div>
    </MBClickOutside>
  );
};

type SearchInputProps = {
  search_active: boolean,
  openSearch: () => void,
  closeSearch: () => void
}

const SearchInput = ({search_active, openSearch, closeSearch}: SearchInputProps) => {
  return (
    <Search
      onClose={closeSearch}
      renderInput={({ value, clear, onKeyDown, onChange, onFocus, onBlur}) => (
        <div className={styles.cmMBrowseBar_Right}>
          <div className={styles.cmMBrowseBar_Search_Wrapper}>
            <MBDynamicIcon
              name="search"
              width={29}
              height={29}
              className={cn('cmMBrowseBar_SearchIcon', {cmMBrowseBar_SearchIcon__SearchActive: search_active})} />
            <MBInput.Input
              value={value}
              onChange={onChange}
              onKeyDown={onKeyDown}
              onFocus={(event) => {
                openSearch();
                onFocus(event);
              }}
              className={styles.cmMBrowseBar_SearchInput}
              placeholder="Search products" />
          </div>
          <MBTouchable
            onClick={clear}
            className={cn('cmMBrowseBar_ClearSearch', {
              cmMBrowseBar_ClearSearch__SearchEmpty: !value,
              cmMBrowseBar_ClearSearch__SearchActive: !search_active
            })}>
            <MBIcon name="clear" />
          </MBTouchable>
          <MBTouchable onClick={() => { onBlur(); closeSearch(); }}>
            <MBText.Span className={cn('cmMBrowseBar_CancelSearch', {cmMBrowseBar_CancelSearch__SearchActive: search_active})}>
              Cancel
            </MBText.Span>
          </MBTouchable>
        </div>
      )} />
  );
};

export default connectToObservables(BrowseBar, {
  location_fragment: locationStream.map((location) => location.fragment)
});
