import React, { Component } from 'react';

export default class SupplierEmailsEdit extends Component {
  constructor (props) {
    super(props);
    this.state = {
      emails: props.emails
    };
  }

  render () {
    const {emails} = this.state;
    return (
      <div>
        {emails.map( (email, index) => <Email key={index} email={email} remove={() => this.remove(index)}/>)}
        <span style={style_add} onClick={this.add}>➕</span>
      </div>
    );
  }

  remove = (index) => {
    const emails = this.state.emails.slice();
    emails[index] = null;
    this.setState({emails});
  };
  add = () => this.setState( ({emails}) => ({emails: [...emails, ""]}) );
}

function Email ({email, remove}) {
  if (email === null)
    return null;
  return (
    <div style={style}>
      <input type="text" name="supplier[emails][]" defaultValue={email} />
      <span style={style_remove} onClick={remove}>❌</span>
    </div>
  );
}

const style = {
  position: 'relative'
};

const style_remove = {
  position: 'absolute',
  top: 10,
  right: 10,
  fontWeight: 'bold',
  fontSize: 20,
  cursor: 'pointer'
};

const style_add = {
  fontWeight: 'bold',
  fontSize: 20,
  cursor: 'pointer'
};
