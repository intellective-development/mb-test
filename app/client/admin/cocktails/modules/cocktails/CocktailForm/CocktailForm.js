import React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { Switch, Route, withRouter } from 'react-router-dom';
import { push } from 'connected-react-router';
import { promisifyRoutine } from 'redux-saga-routines';
import { reduxForm, getFormValues } from 'redux-form';
import { actions as toastr } from 'react-redux-toastr';
import { selectItemByPermalink as selectCocktailByPermalink, GetCocktailRoutine, SetCocktailRoutine } from '../Cocktails.dux';
import CocktailFormPreview from './CocktailFormPreview';
import CocktailFormEdit from './CocktailFormEdit';
import RouteTabs from '../../../../route-tabs';

class CocktailForm extends React.Component {
  submit(values, dispatch){
    return promisifyRoutine(SetCocktailRoutine)(values, dispatch)
      .then(result => {
        dispatch(toastr.add({ type: 'success', title: 'Saved' }));
        dispatch(push('/admin/cocktails'));
        document.location.reload(true);
      })
      .catch(error => {
        dispatch(toastr.add({ type: 'error', title: 'Error saving', message: error.message }));
      });
  }

  componentDidMount(){
    const { match: { params: { cocktailId } = {} } } = this.props;
    if (cocktailId && cocktailId !== 'new'){
      this.props.getCocktail({ id: cocktailId });
    }
  }

  componentDidUpdate(prevProps){
    const { cocktailId: oldCocktailId } = prevProps.match.params || {};
    const { match: { params: { cocktailId } = {} } } = this.props;
    if (cocktailId !== 'new' && cocktailId !== oldCocktailId){
      this.props.getCocktail({ id: cocktailId });
    }
  }

  setActive = () => {
    const { setActive, cocktail } = this.props;
    setActive({ ...cocktail, active: !cocktail.active });
  }

  render(){
    const { handleSubmit, submitting, pristine, invalid, cocktail = {}, match } = this.props;
    const submitTitle = cocktail.id ? 'Update' : 'Create';

    return (
      <div>
        <h1>{cocktail.name || 'Create new cocktail'}</h1>
        <div className="flex-row">
          <div className="flex-item">
            { cocktail.brand ? <div>Recipe by <h6 style={{ display: 'inline', fontWeight: 'bold' }}>{cocktail.brand.name}</h6></div> : null }
          </div>
          <div className="flex-item" />
        </div>
        <RouteTabs tabs={[{
          name: 'Preview',
          path: `${match.url}/preview`
        }, {
          name: 'Edit',
          path: match.url
        }]} />
        <Switch>
          <Route path={`${match.url}/preview`} component={CocktailFormPreview} />
          <Route exact path={`${match.url}`} render={() => <CocktailFormEdit {...cocktail} />} />
        </Switch>
        <div className="flex-row" style={{ justifyContent: 'flex-end' }}>
          <div>
            <button disabled={submitting || this.props.match.params.cocktailId === 'new'} onClick={this.setActive} style={{ margin: '0 10px' }}>{cocktail.active ? 'Deactivate' : 'Activate'}</button>
            <button disabled={submitting || pristine || invalid} onClick={handleSubmit(this.submit.bind(this))}>{submitting ? 'Saving...' : submitTitle }</button>
          </div>
        </div>
      </div>
    );
  }
}

const form = 'Cocktail';

const CocktailFormSTP = (state, { match }) => {
  return ({
    initialValues: selectCocktailByPermalink(state)(match.params.cocktailId),
    cocktail: getFormValues(form)(state)
  });
};

const CocktailFormDTP = ({
  getCocktail: GetCocktailRoutine.trigger,
  setActive: SetCocktailRoutine.trigger
});

export default withRouter(connect(CocktailFormSTP, CocktailFormDTP)(reduxForm({
  form,
  enableReinitialize: true
})(CocktailForm)));
