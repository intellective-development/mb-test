import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { push } from 'connected-react-router';
import { promisifyRoutine } from 'redux-saga-routines';
import { reduxForm, getFormValues } from 'redux-form';
import { actions as toastr } from 'react-redux-toastr';
import { selectItem, GetToolRoutine, SetToolRoutine } from '../Tools.dux';
import ToolFormEdit from './ToolFormEdit';

class ToolForm extends React.Component {
  submit(values, dispatch){
    return promisifyRoutine(SetToolRoutine)(values, dispatch)
      .then(result => {
        dispatch(toastr.add({ type: 'success', title: 'Saved' }));
        const { match: { params: { toolId } = {} } } = this.props;
        if (toolId && toolId === 'new'){
          dispatch(push(this.props.match.url.replace('new', result.id)));
        }
      })
      .catch(error => {
        dispatch(toastr.add({ type: 'error', title: 'Error saving', message: error.message }));
      });
  }

  componentDidMount(){
    const { match: { params: { toolId } = {} } } = this.props;
    if (toolId && toolId !== 'new'){
      this.props.getTool({ id: toolId });
    }
  }

  componentDidUpdate(prevProps){
    const { toolId: oldToolId } = prevProps.match.params || {};
    const { match: { params: { toolId } = {} } } = this.props;
    if (toolId !== 'new' && toolId !== oldToolId){
      this.props.getTool({ id: toolId });
    }
  }

  render(){
    const { handleSubmit, submitting, pristine, tool = {} } = this.props;
    const submitTitle = tool.id ? 'Update' : 'Create';
    return (
      <div>
        <h1>{tool.name || 'Create new tool'}</h1>
        <div className="flex-row">
          <div className="flex-item">
            { tool.brand ? <div>Recipe by <h6 style={{ display: 'inline', fontWeight: 'bold' }}>{tool.brand.name}</h6></div> : null }
          </div>
          <div className="flex-item" />
        </div>
        <ToolFormEdit {...tool} />
        <div className="flex-row" style={{ justifyContent: 'flex-end' }}>
          <div>
            <button disabled style={{ margin: '0 10px' }}>Deactivate</button>
            <button disabled={submitting || pristine} onClick={handleSubmit(this.submit.bind(this))}>{submitting ? 'Saving...' : submitTitle }</button>
          </div>
        </div>
      </div>
    );
  }
}

const form = 'Tool';

const ToolFormSTP = (state, { match }) => {
  return ({
    initialValues: selectItem(state)(match.params.toolId),
    tool: getFormValues(form)(state)
  });
};

const ToolFormDTP = {
  getTool: GetToolRoutine.trigger
};

export default withRouter(connect(ToolFormSTP, ToolFormDTP)(reduxForm({
  form,
  enableReinitialize: true
})(ToolForm)));
