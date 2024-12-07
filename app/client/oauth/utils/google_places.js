import _ from 'lodash';

const getComponentShortName = (components, type) => {
  const selectedComponent = _.find(components, (component) => (
    _.includes(component.types, type)
  ));
  return selectedComponent ? selectedComponent.short_name : '';
};

export default getComponentShortName;
