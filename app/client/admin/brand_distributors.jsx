import React, { Component, createContext, useContext } from 'react';

const BrandDistributorsContext = createContext();

export default class BrandDistributors extends Component {
  constructor(props) {
    super(props);

    const {all_distributors, brand_distributors} = props;
    const selectedDistributors = brand_distributors.reduce(
      (acc, [id, name]) => acc.add(id),
      new Set()
    );
    const otherDistributors = all_distributors.reduce(
      (acc, [id, name]) => selectedDistributors.has(id) ? acc : acc.add(id),
      new Set()
    );
    const distributors = all_distributors.reduce(
      (acc, [id, name]) => ({...acc, [id]: name}),
      {}
    );
    this.state = {
      distributors,
      selectedDistributors,
      otherDistributors
    };
  }
  toggleDistributor = (id) => this.setState( ({selectedDistributors, otherDistributors, ...prevState}) => {
    if (selectedDistributors.has(id)) {
      selectedDistributors = new Set(selectedDistributors);
      otherDistributors = new Set(otherDistributors);
      selectedDistributors.delete(id);
      otherDistributors.add(id);
    }
    else if (otherDistributors.has(id)) {
      selectedDistributors = new Set(selectedDistributors);
      otherDistributors = new Set(otherDistributors);
      selectedDistributors.add(id);
      otherDistributors.delete(id);
    }
    return {...prevState, selectedDistributors, otherDistributors};
  })
  render () {
    const {distributors, selectedDistributors, otherDistributors} = this.state;
    return (
      <BrandDistributorsContext.Provider value={{distributors, selectedDistributors, otherDistributors, toggleDistributor: this.toggleDistributor}}>
        <SelectedDistributors />
        <DistributorSelect />
        {[...selectedDistributors].map( (id) => <input key={id} type="hidden" name="brand[distributor_ids][]" value={id} readOnly/>)}
      </BrandDistributorsContext.Provider>
    );
  }
}

function SelectedDistributors () {
  const {distributors, selectedDistributors, toggleDistributor} = useContext(BrandDistributorsContext);
  return (
    <div>
      {[...selectedDistributors].map( (id) => <div key={id} className={"distributor-item"} onClick={() => toggleDistributor(id)}>{distributors[id]}</div>)}
    </div>
  );
}

function DistributorSelect() {
  const {distributors, otherDistributors, toggleDistributor} = useContext(BrandDistributorsContext);
  const handleOptionSelected = (event) => {
    const {value} = event.target;
    toggleDistributor(parseInt(value));
  };
  return (
    <select onChange={handleOptionSelected} defaultValue="">
      <option value="">-- Select to add a distributor --</option>
      {[...otherDistributors].map( (id) => <option key={id} value={id}>{distributors[id]}</option>)}
    </select>
  );
}
