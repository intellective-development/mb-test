
const localState = ({ variant }) => variant;

export const selectVariantById = state => id => localState(state).by_id[id];
