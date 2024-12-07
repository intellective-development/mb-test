// makeProvided imports the store, which breaks tests.
// here, we mock it with a trivial HOC that just returns the component it receives

const makeProvided = (Component) => Component;

module.exports = makeProvided;
