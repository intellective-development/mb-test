import React from 'react';
import { withRouter, Link } from 'react-router-dom';

const RouteTabs = ({ tabs = [], location }) => (
  <div className="react-tabs" data-tabs="true">
    <ul className="react-tabs__tab-list" role="tablist">
      {
        tabs.map(({ name, path }, index) => {
          const active = path === location.pathname;
          return renderTabLink({ name, path, active, index });
        })
      }
    </ul>
  </div>
);

const renderTabLink = ({ name, active, path, index }) => (
  <Link
    to={path}
    key={index}>
    <li
      className={`react-tabs__tab${(active ? ' react-tabs__tab--selected' : '')}`}
      tabIndex={index}
      id={`react-tabs-${index}`}
      aria-controls={`react-tabs-${index}`}
      aria-selected={active ? 'true' : 'false'}
      role="tab">
      {name}
    </li>
  </Link>
);

export default withRouter(RouteTabs);
