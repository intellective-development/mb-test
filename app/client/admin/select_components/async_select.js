import _ from 'lodash';
import PropTypes from 'prop-types';
import * as React from 'react';
import VirtualizedSelect from 'react-virtualized-select';
import { fetchSellables } from 'admin/admin_api';

//  react-virtualized-select docs: https://github.com/bvaughn/react-virtualized-select
//  react-select docs: https://github.com/JedWatson/react-select/#usage
class AsyncSelect extends React.Component {
  static propTypes = {
    initialValues: PropTypes.array, // promise that returns array of initially selected options in API format
    initialValuesPromise: PropTypes.object, // promise that returns array of initially selected options in API format
    initialValueIds: PropTypes.array, // array of ids to replace initial promise
    formatOptions: PropTypes.func, // function to manipulate API returned option for UI
    type: PropTypes.string, // entity name options, i.e. what is being selected
    label: PropTypes.string // select component label
  };

  static defaultProps = {
    initialValues: [],
    initialValuesPromise: null,
    initialValueIds: [] // array of ids to initialize, in place of promise
  };

  constructor(props){
    super(props);
    const formatter = props.formatOptions;
    this.state = { selectedValues: formatter ? formatter(props.initialValues) : props.initialValues };
  }

  componentDidMount(){
    const formatter = this.props.formatOptions;
    let promise = this.props.initialValuesPromise;
    if (this.props.initialValueIds.length > 0){
      promise = fetchSellables(this.props.type, this.props.initialValueIds); // fetch from endpoint if initial ids supplied
    }
    if (promise){
      promise.then((values) => {
        this.setState({selectedValues: formatter ? formatter(values) : values});
      });
    }
  }

  onChange = (value) => {
    this.setState({
      selectedValues: this.props.multi ? value : [value]
    });
  };

  currentValues = () => {
    return this.props.multi ? this.state.selectedValues : this.state.selectedValues[0];
  };

  render(){
    const admin_props = ['initialValues', 'initialValuesPromise', 'initialValueIds', 'formatOptions', 'type', 'label', 'id'];
    const virtualized_select_props = _.omit(this.props, admin_props);
    return (
      <label htmlFor={`async-select_${this.props.id || this.props.type}`}>
        {this.props.label}
        <VirtualizedSelect
          async
          id={`async-select_${this.props.id || this.props.type}`}
          onChange={this.onChange}
          value={this.currentValues()}
          {...virtualized_select_props} />
      </label>
    );
  }
}

export default AsyncSelect;
