import * as React from 'react';
import _ from 'lodash';
import Banner from './banner';
import CarouselContainer from './carousel_container';
import CarouselItemSelected from './carousel_item_selected';

class App extends React.Component {
  constructor(props){
    super(props);

    const cocktail_from_tag = _.find(props.items, (obj) => { return obj.tag === props.cocktail_tag; });
    const cocktail = cocktail_from_tag || props.items[0];

    this.state = {selectedItem: cocktail};
  }

  render(){
    return (
      <div>
        <Banner />
        <CarouselContainer
          items={this.props.items}
          onItemSelect={selectedItem => this.setState({selectedItem})}
          selectedItem={this.state.selectedItem} />
        <CarouselItemSelected item={this.state.selectedItem} />
      </div>
    );
  }
}

export default App;
