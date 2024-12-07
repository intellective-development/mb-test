import _ from 'lodash';
import { createRoutine } from 'redux-saga-routines';
import { handleActions } from 'redux-actions';
import { STATUS, mapToArray, arrayToMap } from '@minibar/store-business/src/utils/redux-utils';

const ENTITY = 'cocktail';

const initialState = {
  status: STATUS.IDLE,
  payload: {},
  by_permalink: {}
};

export const GetCocktailsRoutine = createRoutine(`${ENTITY.toUpperCase()}S/LIST`);
export const GetCocktailRoutine = createRoutine(`${ENTITY.toUpperCase()}/GET`);
export const SetCocktailRoutine = createRoutine(`${ENTITY.toUpperCase()}/SET`);

const parseItem = ({ tools, ingredients, ...item }) => ({
  ...item,
  tools: _.compact(tools),
  ingredients: _.compact(ingredients)
});

export const stringifyItem = ({ tags, tools, instructions, ingredients, images, ...rest }) => {
  const item = _.omit(rest, 'status');
  return ({
    ...item,
    tags: _.compact(tags),
    instructions: _.compact(instructions),
    tools: _.compact(tools),
    ingredients: _.compact(ingredients),
    images: _.compact(images)
  });
};

/*** TODO: filters, pages, terms */
export default handleActions({
  /*** COCKTAIL LIST */
  [GetCocktailsRoutine.TRIGGER]: (state) => {
    return {
      ...state,
      status: STATUS.FETCHING
    };
  },
  [GetCocktailsRoutine.SUCCESS]: (state, {payload}) => {
    const items = _.map(payload, parseItem);
    const resultMap = arrayToMap(items);
    const by_permalink = arrayToMap(items, 'permalink', ({ id }) => id);
    return {
      ...state,
      payload: {
        ...state.payload,
        ...resultMap
      },
      by_permalink
    };
  },
  [GetCocktailsRoutine.FULFILL]: (state) => ({
    ...state,
    status: STATUS.FETCHED
  }),

  /*** SINGLE COCKTAIL */
  [GetCocktailRoutine.TRIGGER]: (state, { payload: { id }}) => ({
    ...state,
    payload: {
      [id]: {
        ...state.payload[id],
        status: STATUS.FETCHING
      }
    }
  }),
  [GetCocktailRoutine.SUCCESS]: (state, { payload }) => ({
    ...state,
    payload: {
      ...state.payload,
      [payload.id]: {
        ...state.payload[payload.id],
        ...parseItem(payload)
      }
    },
    by_permalink: {
      ...state.by_permalink,
      [payload.permalink]: payload.id
    }
  }),
  [GetCocktailRoutine.FULFILL]: (state, { payload }) => ({
    ...state,
    payload: {
      ...state.payload,
      [payload.id]: {
        ...state.payload[payload.id],
        status: STATUS.FETCHED
      }
    }
  }),
  [SetCocktailRoutine.SUCCESS]: (state, { payload }) => ({
    ...state,
    payload: {
      ...state.payload,
      [payload.id]: {
        ...state.payload[payload.id],
        ...parseItem(payload)
      }
    },
    by_permalink: {
      ...state.by_permalink,
      [payload.permalink]: payload.id
    }
  })
}, initialState);

const localState = state => state.cocktails;
export const selectItem = (state) => (id) => localState(state).payload[id];
export const selectItemByPermalink = (state) => (permalink) => selectItem(state)(localState(state).by_permalink[permalink]);
export const selectItems = (state) => mapToArray(localState(state).payload);
