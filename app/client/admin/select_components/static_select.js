import _ from 'lodash';
import PropTypes from 'prop-types';
import * as React from 'react';
import VirtualizedSelect from 'react-virtualized-select';

//  react-virtualized-select docs: https://github.com/bvaughn/react-virtualized-select
//  react-select docs: https://github.com/JedWatson/react-select/#usage
class StaticSelect extends React.Component {
  static propTypes = {
    initialValues: PropTypes.array,
    label: PropTypes.string
  };

  static defaultProps = {
    initialValues: []
  };

  constructor(props){
    super(props);
    this.state = { selectedValues: this.props.initialValues };
  }

  onChange = (value) => {
    this.setState({
      selectedValues: this.props.multi ? value : [value]
    });
  };

  currentValues = () => {
    let selectValues = this.state.selectedValues;
    if ((!selectValues || selectValues.length === 0) && (this.props.selectedValues && this.props.selectedValues.length > 0)){
      selectValues = this.props.selectedValues;
    }
    return this.props.multi ? selectValues : selectValues[0];
  };

  render(){
    const admin_props = ['initialValues', 'label'];
    const virtualized_select_props = _.omit(this.props, admin_props);
    return (
      <label htmlFor={`static-select_${this.props.label}`}>
        {this.props.label}
        <VirtualizedSelect
          id={`static-select_${this.props.label}`}
          onChange={this.onChange}
          value={this.currentValues()}
          {...virtualized_select_props} />
      </label>
    );
  }
}

export default StaticSelect;
