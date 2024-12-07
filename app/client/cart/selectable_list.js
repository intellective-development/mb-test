// @flow
import * as React from 'react';

type SelectableListProps<T> = {
  items: T[],
  display_count: number;
  renderContainer: (content: React.Node) => React.Node;
  renderItem: (item: T, selectItem: () => void) => React.Node
}

type SelectableListState = {
  displayed_item_indices: number[],
  next_item_index: number
}

export const initialState = ({ display_count }: SelectableListProps<*>) => ({
  displayed_item_indices: Array.from(Array(display_count).keys()), // Array x of length display_count with x[n] = n
  next_item_index: display_count
});

export const getNextItemIndex = (current_index: number, displayed_item_indices: number[], item_count: number) => {
  if (displayed_item_indices.length === item_count) return undefined;

  let next_item_index = current_index;
  // This loop makes sure the next index increments at least one, and is not already displayed.
  // It keeps incrementing if the new next index is already displayed.
  do {
    next_item_index = (next_item_index + 1) % item_count;
  } while (displayed_item_indices.indexOf(next_item_index) > -1);

  return next_item_index;
};

export const makeSelectIndexState = (display_index) => (state: SelectableListState, { items, display_count }: SelectableListProps<*>) => {
  if (items.length <= display_count){ // If there are no extra items, do not shuffle list
    return state;
  }

  const displayed_item_indices = [...state.displayed_item_indices];
  displayed_item_indices[display_index] = state.next_item_index;

  const next_item_index = getNextItemIndex(
    state.next_item_index,
    displayed_item_indices,
    items.length
  );

  return { displayed_item_indices, next_item_index };
};

export const makeDisplayFewerItemsState = (_props, next_props: SelectableListProps<*>) => (state: SelectableListState) => ({
  ...state,
  displayed_item_indices: state.displayed_item_indices.slice(0, next_props.display_count)
});

// TODO Clean this up function if possible
export const makeDisplayMoreItemsState = (props: SelectableListProps<*>, next_props: SelectableListProps<*>) => (state: SelectableListState) => {
  const extra_item_count = next_props.display_count - props.display_count;
  const new_item_indices = state.displayed_item_indices;
  new_item_indices.push(state.next_item_index);

  for (let index = 0; index < extra_item_count - 1; index += 1){
    new_item_indices.push(getNextItemIndex(
      new_item_indices[new_item_indices.length - 1],
      new_item_indices,
      next_props.items.length
    ));
  }

  const next_item_index = getNextItemIndex(
    new_item_indices[new_item_indices.length - 1],
    new_item_indices,
    next_props.items.length
  );

  return {
    ...state,
    displayed_item_indices: new_item_indices,
    next_item_index
  };
};

export default class SelectableList extends React.Component<SelectableListProps<*>, SelectableListState> {
  constructor(props: SelectableListProps<*>){
    super(props);
    this.state = initialState(props);
  }

  componentWillReceiveProps(next_props: SelectableListProps<*>){
    // Generally will only go from 0 to >0 once, this is to catch if loading finishes after component mount
    if (next_props.items.length !== this.props.items.length){
      this.setState(initialState(next_props));
    }

    if (next_props.display_count < this.props.display_count){
      this.setState(makeDisplayFewerItemsState(this.props, next_props));
    } else if (next_props.display_count > this.props.display_count){
      this.setState(makeDisplayMoreItemsState(this.props, next_props));
    }
  }

  selectItem = (display_index: number) => this.setState(makeSelectIndexState(display_index));

  render(){
    const { items, renderItem, renderContainer = renderSpan } = this.props;
    const { displayed_item_indices } = this.state;
    const content = displayed_item_indices.map((item_index, display_index) => {
      const item = items[item_index];

      if (!item) return null; // if there are less items than max display count

      return renderItem(item, () => this.selectItem(display_index));
    });

    return renderContainer(content);
  }
}

const renderSpan = (content) => (<span>{content}</span>);
