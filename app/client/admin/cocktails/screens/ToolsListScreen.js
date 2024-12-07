import React from 'react';
import { Link } from '../../../shared/nav_utils';
import ToolsList from '../modules/tools/ToolsList';

const ToolsListScreen = ({ match }) => (
  <div>
    <h1>Tools</h1>
    <Link to={`${match.url}/edit/new`} className="button">Add new</Link>
    <ToolsList />
  </div>
);

export default ToolsListScreen;
