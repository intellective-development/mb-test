import React, { PureComponent } from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { Link } from '../../../../shared/nav_utils';
import { GetToolsRoutine, selectItems as selectTools } from './Tools.dux';

const ToolRow = withRouter(({ id, name, brand = {}, match }) => {
  return (
    <div className="row" key={id}>
      <div className="col">{name}</div>
      <div className="col">{brand ? brand.name : ''}</div>
      <div className="col">
        <Link to={`${match.url}/edit/${id}`} className="button">Edit</Link>
      </div>
    </div>
  );
});

const renderToolRow = (tool) => <ToolRow key={tool.id} {...tool} />;

class ToolsList extends PureComponent {
  componentDidMount(){
    this.props.getTools();
  }

  render(){
    const { tools } = this.props;
    return (
      <div className="table">
        <div className="row thead">
          <div className="col">Name</div>
          <div className="col">Brand</div>
          <div className="col">Actions</div>
        </div>
        {
          _.map(tools, renderToolRow)
        }
      </div>
    );
  }
}

const ToolsListSTP = (state) => {
  return {
    tools: selectTools(state)
  };
};

const ToolsListDTP = {
  getTools: GetToolsRoutine.trigger
};

export default connect(ToolsListSTP, ToolsListDTP)(ToolsList);
