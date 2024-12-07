// @flow

import * as React from 'react';

import Search from '../shared/Search';
import { MBDynamicIcon, MBLoader, MBInput } from '../../../elements';
import styles from './BrowseBar.scss';
import './SearchInput.scss';

const SearchInput = () => (
  <div className={styles.cmDBrowseBar_Search_Container}>
    <Search
      renderInput={({ value, onKeyDown, onChange, onFocus, is_loading}) => (
        <div className={styles.cmDBrowseBar_Search_Wrapper}>
          <MBDynamicIcon
            name="search"
            className={styles.cmDBrowseBar_Search_Icon}
            width={26}
            height={26} />
          <MBInput.Input
            id="search"
            placeholder="Search products, categories, brands"
            type="search"
            value={value}
            className={styles.cmDBrowseBar_Search_Input}
            onChange={onChange}
            onKeyDown={onKeyDown}
            onFocus={onFocus}
            autoComplete={'off'} />
          {is_loading && (<MBLoader className={'cmSearchInput__Loader'} />)}
        </div>
      )} />
  </div>
);

export default SearchInput;
