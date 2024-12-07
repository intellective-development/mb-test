// @flow

const immutableInsert = (items: Array<*>, index: number, ...new_items: Array<*>) => ([
  ...items.slice(0, index), // items before index
  ...new_items, // new items
  ...items.slice(index) // rest of items
]);

export default immutableInsert;
