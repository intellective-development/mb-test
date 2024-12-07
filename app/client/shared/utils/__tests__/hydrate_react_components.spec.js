import * as React from 'react';
import hydrateReactComponents, { hydrateComponent } from '../hydrate_react_components';
import renderComponentRoot from '../render_component_root';
import { encodeObject } from '..//convert_utf8_b64';

jest.mock('../render_component_root');

describe('hydrateReactComponents', () => {
  it('iterates over the elements marked with data-react-client-render and rehydrates them', () => {
    const ComponentOne = () => null;
    const ComponentTwo = () => null;
    const component_one_props = {};
    const component_two_props = {foo: 'bar'};

    // Set up our document body
    document.body.innerHTML =
      `<div id="1" data-react-client-render data-react-component-name="ComponentOne" data-react-component-props="${encodeObject(component_one_props)}" />` +
      `<div id="2" data-react-client-render data-react-component-name="ComponentTwo" data-react-component-props="${encodeObject(component_two_props)}" />`;

    const node_one = document.getElementById('1');
    const node_two = document.getElementById('2');

    hydrateReactComponents({ComponentOne, ComponentTwo})();

    expect(renderComponentRoot.mock.calls[0]).toEqual([<ComponentOne {...component_one_props} />, node_one]);
    expect(renderComponentRoot.mock.calls[1]).toEqual([<ComponentTwo {...component_two_props} />, node_two]);
  });

  it('iterates and ignores elements without the data-react-client-render attribute', () => {
    const ComponentOne = () => null;
    const ComponentTwo = () => null;
    const component_one_props = {};
    const component_two_props = {foo: 'bar'};

    // Set up our document body
    document.body.innerHTML =
      `<div id="1" data-react-component-name="ComponentOne" data-react-component-props="${encodeObject(component_one_props)}" />` +
      `<div id="2" data-react-client-render data-react-component-name="ComponentTwo" data-react-component-props="${encodeObject(component_two_props)}" />`;

    const node_two = document.getElementById('2');

    hydrateReactComponents({ComponentOne, ComponentTwo})();

    expect(renderComponentRoot.mock.calls[0]).toEqual([<ComponentTwo {...component_two_props} />, node_two]);
    expect(renderComponentRoot.mock.calls.length).toEqual(1);
  });
});

describe('hydrateComponent', () => {
  const fakeGetAttribute = (attributes) => (attr_key) => attributes[attr_key];
  const original_console_warn = console.error;
  beforeEach(() => {
    global.console.warn = jest.fn(original_console_warn);
  });
  afterAll(() => {
    global.console.warn = original_console_warn;
  });

  it('renders out a component for a given node', () => {
    const MyComponent = () => {};
    const component_node = {
      getAttribute: fakeGetAttribute({
        'data-react-component-name': 'MyComponent'
      })
    };

    hydrateComponent(component_node, {MyComponent});
    expect(renderComponentRoot).toHaveBeenCalledWith(<MyComponent />, component_node);
    expect(console.warn).not.toHaveBeenCalled();
  });

  it('renders a component with props', () => {
    const MyComponent = () => {};
    const props = {foo: 'bar'};
    const component_node = {
      getAttribute: fakeGetAttribute({
        'data-react-component-name': 'MyComponent',
        'data-react-component-props': encodeObject(props)
      })
    };

    hydrateComponent(component_node, {MyComponent});
    expect(renderComponentRoot).toHaveBeenCalledWith(<MyComponent {...props} />, component_node);
    expect(console.warn).not.toHaveBeenCalled();
  });

  it('logs a warning if component is not present in component_map', () => {
    const component_node = {
      getAttribute: fakeGetAttribute({
        'data-react-component-name': 'MyComponent'
      })
    };

    hydrateComponent(component_node, {OtherComponent: () => null});
    expect(renderComponentRoot).not.toHaveBeenCalled();
    expect(console.warn).toHaveBeenCalledWith('No entry named MyComponent present in [OtherComponent]. Did you mean to pass it in?');
  });
});
