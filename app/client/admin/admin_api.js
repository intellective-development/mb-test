import 'whatwg-fetch';
import FormDataMapper from 'object-to-formdata';

const ADMIN_API_BASE = '/api/admin/v1/';
const AUTH_HEADERS = {
  headers: {
    Authorization: `bearer ${window.User.access_token}`
  }
};

// TODO: BC: make a generalized format for React Virtualized Select options object function
//  and remove imperative formatting from fetch functions

const handleErrors = (response) => {
  if (!response.ok){
    throw Error(response.statusText);
  }
  return response;
};

export const fetchBrands = (input) => (
  fetch(`${ADMIN_API_BASE}brands?query=${input}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then((json) => ({ options: json.brands }))
    .catch(error => console.error(error))
);

export const fetchCocktails = (query) => (
  fetch(`${ADMIN_API_BASE}cocktails/search?query=${query}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then(result => result.map(({ id, name }) => ({ value: id, label: name })))
    .then((json) => ({ options: json }))
    .catch(error => console.error(error))
);

export const fetchProducts = (input) => (
  fetch(`${ADMIN_API_BASE}products?query=${input}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then((json) => ({ options: json.products }))
    .catch(error => console.error(error))
);

export const fetchProductTypes = (input) => (
  fetch(`${ADMIN_API_BASE}product_types?query=${input}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then((json) => ({ options: json.types }))
    .catch(error => console.error(error))
);

export const fetchProductGroupings = (input) => (
  fetch(`${ADMIN_API_BASE}product_size_groupings?query=${input}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then((json) => { return { options: json }; })
    .catch(error => console.error(error))
);

export const fetchSuppliers = (input) => (
  fetch(`${ADMIN_API_BASE}suppliers?query=${input}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then((json) => ({ options: json.suppliers }))
    .catch(error => console.error(error))
);

export const fetchUsers = (input) => (
  fetch(`${ADMIN_API_BASE}users?query=${input}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then((json) => ({ options: json.users }))
    .catch(error => console.error(error))
);

export const fetchPaymentProfiles = (user_id) => (
  fetch(`${ADMIN_API_BASE}payment_profiles?user_id=${user_id}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then((json) => ( json.payment_profiles ))
    .catch(error => console.error(error))
);

export const fetchSellables = (type, ids, coupon_id) => {
  const options = { sellable_type: type, sellable_ids: ids };

  if (coupon_id && ids.length > 10){ // allow fetching by coupon id for big payloads (413)
    delete options.sellable_ids;
    options.fetch_from_coupon_id = coupon_id;
  }

  return fetch(`${ADMIN_API_BASE}sellables?${$.param(options)}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then((json) => (json.sellables))
    .catch(error => console.error(error));
};

export const fetchCocktailsList = () => {
  return fetch(`${ADMIN_API_BASE}cocktails`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json());
};
export const searchCocktailsList = (query) => {
  return fetch(`${ADMIN_API_BASE}cocktails/search?query=${query}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then(result => result.map(({ id, name }) => ({ id, name })));
};

export const fetchCocktail = ({ id }) => {
  return fetch(`${ADMIN_API_BASE}cocktails/${id}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json());
};

export const postCocktail = (cocktail) => {
  const update = !!cocktail.id;

  const headers = {
    ...AUTH_HEADERS.headers
  };
  const opts = {
    headers,
    body: FormDataMapper(cocktail, { indices: true }),
    method: update ? 'PUT' : 'POST'
  };
  return fetch(`${ADMIN_API_BASE}cocktails${update ? `/${cocktail.permalink}` : ''}`, opts)
    .then(handleErrors)
    .then((response) => response.json());
};

export const searchBrands = (searchText) => {
  return fetch(`${ADMIN_API_BASE}brands/search?q=${searchText}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json());
};

export const fetchToolsList = () => {
  return fetch(`${ADMIN_API_BASE}tools`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json());
};
export const searchToolsList = (query) => {
  return fetch(`${ADMIN_API_BASE}tools/search?query=${query}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json())
    .then(result => result.map(({ id, name }) => ({ id, name })));
};

export const fetchTool = ({ id }) => {
  return fetch(`${ADMIN_API_BASE}tools/${id}`, AUTH_HEADERS)
    .then(handleErrors)
    .then((response) => response.json());
};

export const postTool = (tool) => {
  const update = !!tool.id;

  const headers = {
    ...AUTH_HEADERS.headers
  };
  const opts = {
    headers,
    body: FormDataMapper(tool, { indices: true }),
    method: update ? 'PUT' : 'POST'
  };
  return fetch(`${ADMIN_API_BASE}tools${update ? `/${tool.id}` : ''}`, opts)
    .then(handleErrors)
    .then((response) => response.json());
};
