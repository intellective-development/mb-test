// @flow
import * as React from 'react';
import _ from 'lodash';

import bindClassNames from 'shared/utils/bind_classnames';
import I18n from 'store/localization';
import type { AutocompleteResult } from 'store/business/autocomplete';
import { MBText, MBTextWithMatches, MBTouchable, makeMatches } from '../../../elements';
import styles from './AutocompleteDropdown.scss';

const cn = bindClassNames(styles);

export type AutocompleteDropdownProps = {
  show: boolean,
  query_string: string,
  results: AutocompleteResult[],
  selectResult(type: AutocompleteResultType, permalink: string): void
}

const MAX_RESULTS_LENGTH = 10;

export default class AutocompleteDropdown extends React.Component<AutocompleteDropdownProps> {
  renderCategory = (category: AutocompleteResult) => (
    <span key={category.type}>
      <MBText.Span className={'cmAutocompleteDropdown__CategoryName'}>
        {I18n.t(`ui.nav.autocomplete_dropdown.${category.type}`)}
      </MBText.Span>
      {category.items.map(this.renderItem)}
      {category.type === 'product' && this.props.results.length >= MAX_RESULTS_LENGTH && (
        <MBText.A
          onClick={() => this.props.selectResult('search', this.props.query_string, this.props.query_string)}
          className={'cmAutocompleteDropdown__SeeAllLink'}>
          {I18n.t('ui.nav.autocomplete_dropdown.see_all')}
        </MBText.A>
      )}
    </span>
  );

  renderItem = (item) => (
    <MBTouchable
      key={item.permalink}
      onClick={() => this.props.selectResult(item.type, item.permalink, this.props.query_string)}
      className={cn('cmAutocompleteDropdown__Result', { 'cmAutocompleteDropdown__Result--Selected': item.is_selected })}>
      <MBTextWithMatches
        match_classname={'cmAutocompleteDropdown__MatchedText'}
        matches={makeMatches(item.name, this.props.query_string)}>
        {item.name}
      </MBTextWithMatches>
    </MBTouchable>
  );

  render(){
    const { show, results } = this.props;
    const grouped_results = _.groupBy(results, 'type');
    const categories = Object
      .entries(grouped_results)
      .map(([category_type, items]) => ({
        type: category_type,
        items
      }));

    const contents = categories.map(this.renderCategory);
    const show_dropdown = show && !_.isEmpty(categories);

    return (
      <div className={cn('cmAutocompleteDropdown', { 'cmAutocompleteDropdown--show': show_dropdown })}>
        {contents}
      </div>
    );
  }
}
