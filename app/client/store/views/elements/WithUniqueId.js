// @flow

import * as React from 'react';
import uuid from 'uuid';

/*
In numerous places, we need to associate a specific instance of a ui component with a unique entity in the store.
However, if the element that we want to create the id is also should also be getting the entity as a prop through `connect(...)`,
we're stuck. This wraps the component returned from connect with a tiny component that creates the unique id per instance.
*/

const withUniqueId = (prop_name: string = 'id') => (WrappedComponent: React.ComponentType<*>) => {
  class UniqueId extends React.Component<*> {
    unique_id = uuid();

    render(){
      const child_props = {
        [prop_name]: this.unique_id,
        ...this.props
      };

      return <WrappedComponent {...child_props} />;
    }
  }

  const wrapped_component_name = WrappedComponent.displayName || WrappedComponent.name || 'Component';
  UniqueId.displayName = `UniqueId(${wrapped_component_name})`;

  return UniqueId;
};

export default withUniqueId;
