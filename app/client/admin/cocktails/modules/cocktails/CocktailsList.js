import React, { PureComponent } from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { Link } from '../../../../shared/nav_utils';
import { GetCocktailsRoutine, selectItems as selectCocktails } from './Cocktails.dux';

const renderTool = tool => <li>{tool.name}</li>;
const renderIngredient = ingredient => <li>{ingredient.name}</li>;

const CocktailRow = withRouter(({ id, name, brand = {}, tools = [], ingredients = [], match, permalink }) => {
  return (
    <div className="row" key={id}>
      <div className="col">{name}</div>
      <div className="col">{brand ? brand.name : ''}</div>
      <ul className="col">{_.map(tools, renderTool)}</ul>
      <ul className="col">{_.map(ingredients, renderIngredient)}</ul>
      <div className="col">
        <Link to={`${match.url}/edit/${permalink}`} className="button">Edit</Link>
      </div>
    </div>
  );
});

const renderCocktailRow = (cocktail) => <CocktailRow key={cocktail.id} {...cocktail} />;

class CocktailList extends PureComponent {
  render(){
    const { cocktails } = this.props;
    return (
      <div className="table">
        <div className="row thead">
          <div className="col">Name</div>
          <div className="col">Brand</div>
          <div className="col">Tools</div>
          <div className="col">Ingredients</div>
          <div className="col">Actions</div>
        </div>
        {
          _.map(cocktails, renderCocktailRow)
        }
      </div>
    );
  }
}

const CocktailListSTP = (state) => {
  return {
    cocktails: selectCocktails(state)
  };
};

const CocktailListDTP = {
  getCocktails: GetCocktailsRoutine.trigger
};

export default connect(CocktailListSTP, CocktailListDTP)(CocktailList);
