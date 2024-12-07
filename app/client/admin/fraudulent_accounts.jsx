import React, { Component } from 'react';

export default class FraudulentAccounts extends Component {
  constructor (props) {
    super(props);
    this.state = {
      selected_accounts: props.initial_related_accounts
    };
  }

  render () {
    const {fraudulent_account, related_accounts} = this.props;
    return (
      <div>
        <Abuses
           selected_accounts={this.state.selected_accounts}
           toggleAccount={this.toggleAccount}
           related_accounts={related_accounts}
           />
        <SelectedAccounts
           selected_accounts={this.state.selected_accounts}
           toggleAccount={this.toggleAccount}
           fraudulent_account={fraudulent_account}
           />
        <FormForFraudulentOrder
           selected_accounts={this.state.selected_accounts}
           />
      </div>
    );
  }

  toggleAccount = (account) => this.setState( (prevState) => (
    prevState.selected_accounts.find( (selected_account) => account.id === selected_account.id ) ?
      { selected_accounts: prevState.selected_accounts.filter( (selected_account) => account.id !== selected_account.id ) } // Remove if present
    : { selected_accounts: [...prevState.selected_accounts, account] } // Add if absent
  ))
}

function Abuses ({selected_accounts, toggleAccount, related_accounts}) {
  const abuse_list = related_accounts && Object.entries(related_accounts).map( ([abuse_type, abuse_value]) => abuse_value && (
    <Abuse
       key={abuse_type}
       selected_accounts={selected_accounts}
       toggleAccount={toggleAccount}
       abuse_type={abuse_type}
       abuse_value={abuse_value}
       />
  ));
  return (<div>{abuse_list}</div>);
}

function Abuse ({selected_accounts, toggleAccount, abuse_type, abuse_value}) {
  return (
    <div>
      <div><strong>{abuse_type}</strong> ({(abuse_value.score * 100).toFixed(1)})</div>
      <Reasons
         selected_accounts={selected_accounts}
         toggleAccount={toggleAccount}
         reasons={abuse_value.reasons}
         />
    </div>
  );
}


function Reasons ({selected_accounts, toggleAccount, reasons}) {
  const reason_list = reasons && reasons.map( ({name, accounts}) => accounts && (
    <Reason
       key={name}
       selected_accounts={selected_accounts}
       toggleAccount={toggleAccount}
       name={name}
       accounts={accounts}
       />
  ));
  return (<div>{reason_list}</div>);
}

function Reason ({selected_accounts, toggleAccount, name, accounts}) {
  const abuser_list = accounts && accounts.map( (account) => account && (
    <Abuser
       key={account.id}
       selected_accounts={selected_accounts}
       toggleAccount={toggleAccount}
       account={account}
       />
  ));
  return (
    <div>
      <div><label>{name}</label></div>
      {abuser_list}
    </div>
  );
}

function Abuser ({selected_accounts, toggleAccount, account}) {
  const selected = selected_accounts.find( (selected_account) => account.id === selected_account.id );
  return (
    <label
       onClick={() => toggleAccount(account)}
       className={"fraud-dialog__type-option-account-small" + (selected ? "-alert " : "")}
      >
      ({account.code}) {account.email}
    </label>
  );
}

function SelectedAccounts ({selected_accounts, toggleAccount, fraudulent_account}) {
  const account_list = selected_accounts.map( (account) => account && (
    <Account
       key={account.id}
       toggleAccount={toggleAccount}
       account={account}
       />
  ));
  return (
    <div>
      <div><strong>Selected Accounts</strong></div>
      <div className="fraud-dialog__type-option-account-list">
        <Account
           key={fraudulent_account.id}
           toggleAccount={() => {}}
           account={fraudulent_account}
           />
        {account_list}
      </div>
    </div>
  );
}

function Account ({toggleAccount, account}) {
  return (
    <span
       className="fraud-dialog__type-option-account"
       onClick={() => toggleAccount(account)}
       >
      ({account.code}) {account.email}
    </span>
  );
}

function FormForFraudulentOrder ({selected_accounts}) {
  return (
    <div>
      {selected_accounts.map( (account) => account && (
        <input
           type="hidden"
           key={account.id}
           name="fraudulent_order[related_user_ids][]"
           value={account.id}
           />
      ))}
    </div>
  );
}
