import PropTypes from 'prop-types';
import * as React from 'react';

class SimpleInput extends React.Component {
  static propTypes = {
    initialValue: PropTypes.string,
    label: PropTypes.string
  };

  static defaultProps = {
    initialValue: ''
  };

  constructor(props){
    super(props);
    this.state = {selectedValue: this.props.initialValue};
  }

  onChange = (e) => {
    this.setState({
      selectedValue: e.target.value
    });
  };

  render(){
    return (
      <label htmlFor={`static-input_${this.props.label}`}>
        {this.props.label}
        <input
          id={`static-input_${this.props.label}`}
          onChange={this.onChange}
          value={this.state.selectedValue}
          placeholder={this.props.placeholder}
          type={this.props.type} />
        <input
          type="hidden"
          name={this.props.name}
          value={this.state.selectedValue}
          disabled={!this.state.selectedValue} />
      </label>
    );
  }
}

export default SimpleInput;
