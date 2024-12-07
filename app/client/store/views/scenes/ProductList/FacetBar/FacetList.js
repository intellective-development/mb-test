// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { filter_helpers } from 'store/business/filter';
import type { Filter } from 'store/business/filter';
import { product_list_constants, product_list_actions } from 'store/business/product_list';
import classNames from 'classnames';

type FacetListProps = {
  facets: product_list_constants.Facet[],
  filter: Filter,
  product_list_id: string,

  // DTP
  setFilter: typeof product_list_actions.setFilter
};
const FacetList = ({facets, filter, product_list_id, setFilter}: FacetListProps) => {
  const valid_facets = facets.filter(facet => !_.isEmpty(facet.terms));
  return (
    <ul id="facet-list" className="inline-list">
      {valid_facets.map((facet) => (
        <FacetElement
          facet={facet}
          filter={filter}
          setFilter={setFilter}
          product_list_id={product_list_id}
          key={facet.name} />
      ))}
    </ul>
  );
};

type FacetElementProps = {
  filter: Filter,
  facet: product_list_constants.Facet,
  setFilter: typeof product_list_actions.setFilter,
  product_list_id: string
};
class FacetElement extends React.Component<FacetElementProps> {
  chooseOption = (option_term: mixed) => {
    const { filter, facet, setFilter, product_list_id } = this.props;
    const next_filter = filter_helpers.toggleFilterProperty(filter, facet.name, option_term);

    setFilter(product_list_id, next_filter);
    this.closeDropdown();
  };

  closeDropdown = () => {
    if (this.dropdown_toggle){
      this.dropdown_toggle.click(); // make the foundation dropdown close
    }
  };

  render(){
    const { filter, facet } = this.props;
    const dropdown_id = `dropdown-${facet.name}`;

    const facet_options = facet.terms.map((option) => {
      const selected_facet_vals = _.toArray(filter[facet.name]);
      const is_selected = selected_facet_vals.includes(option.term);

      return <FacetOption option={option} selected={is_selected} select={this.chooseOption} key={option.term} />;
    });

    return (
      <li className="facet">
        <a data-dropdown={dropdown_id} className="dropdown" ref={(el) => { this.dropdown_toggle = el; }}>{_.startCase(facet.display_name)}</a>
        <ul id={dropdown_id} data-dropdown-content className="f-dropdown">
          {facet_options}
        </ul>
      </li>
    );
  }
}

type FacetOptionProps = {
  option: product_list_constants.FacetTerm,
  selected: boolean,
  select: mixed => void
};
const FacetOption = ({option, selected, select}: FacetOptionProps) => {
  const link_classes = classNames('facet-option', {selected: selected});
  const description = _.startCase(option.description);
  const handleClick = (e) => {
    e.preventDefault();
    select(option.term);
  };

  return (
    <li>
      <a href="#" className={link_classes} onClick={handleClick}>
        {description}&nbsp;<span>({option.count})</span>
      </a>
    </li>
  );
};

const FacetListDTP = { setFilter: product_list_actions.setFilter };
const FacetListContainer = connect(null, FacetListDTP)(FacetList);

export default FacetListContainer;
