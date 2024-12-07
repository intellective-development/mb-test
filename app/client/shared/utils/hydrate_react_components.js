// @flow

import * as React from 'react';
import renderComponentRoot from 'shared/utils/render_component_root';
import { decodeObject } from 'shared/utils/convert_utf8_b64';

type ComponentMap = {[string]: React.ComponentType<*>};
const hydrateReactComponents = (component_map: ComponentMap) => () => {
  const elements = document.querySelectorAll('[data-react-client-render]');

  // TODO: we use a for loop here to support IE 11. We should look to replace this with NodeList#forEach when core-js supports it.
  for (let i = 0; i < elements.length; i += 1){
    hydrateComponent(elements[i], component_map);
  }
};

export const hydrateComponent = (component_node: HTMLElement, component_map: ComponentMap) => {
  const component_name = component_node.getAttribute('data-react-component-name');
  const component_props = component_node.getAttribute('data-react-component-props');
  const HydrateableComponent = component_name && component_map[component_name];

  if (!HydrateableComponent){
    console.warn(`No entry named ${String(component_name)} present in [${Object.keys(component_map).join(', ')}]. Did you mean to pass it in?`);
    return null;
  }

  return renderComponentRoot(<HydrateableComponent {...decodeObject(component_props)} />, component_node);
};

export default hydrateReactComponents;
