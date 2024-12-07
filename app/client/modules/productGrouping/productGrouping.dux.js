
const localState = ({ product_grouping }) => product_grouping;

export const selectProductGroupingById = state => id => localState(state).by_id[id];
