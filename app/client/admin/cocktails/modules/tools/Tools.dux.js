import _ from 'lodash';
import { createRoutine } from 'redux-saga-routines';
import { handleActions } from 'redux-actions';
import { STATUS, mapToArray, arrayToMap } from '@minibar/store-business/src/utils/redux-utils';

const ENTITY = 'tool';

const initialState = {
  status: STATUS.IDLE,
  payload: {},
  by_permalink: {}
};

export const GetToolsRoutine = createRoutine(`${ENTITY.toUpperCase()}S/LIST`);
export const GetToolRoutine = createRoutine(`${ENTITY.toUpperCase()}/GET`);
export const SetToolRoutine = createRoutine(`${ENTITY.toUpperCase()}/SET`);

const parseItem = ({ ...item }) => ({
  ...item
});

export const stringifyItem = ({ description, images, ...rest }) => {
  const item = _.omit(rest, 'status');
  return ({
    ...item,
    description: description || '',
    images: _.compact(images)
  });
};

/*** TODO: filters, pages, terms */
export default handleActions({
  /*** TOOL LIST */
  [GetToolsRoutine.TRIGGER]: (state) => {
    return {
      ...state,
      status: STATUS.FETCHING
    };
  },
  [GetToolsRoutine.SUCCESS]: (state, {payload}) => {
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
  [GetToolsRoutine.FULFILL]: (state) => ({
    ...state,
    status: STATUS.FETCHED
  }),

  /*** SINGLE Tool */
  [GetToolRoutine.TRIGGER]: (state, { payload: { id }}) => ({
    ...state,
    payload: {
      [id]: {
        ...state.payload[id],
        status: STATUS.FETCHING
      }
    }
  }),
  [GetToolRoutine.SUCCESS]: (state, { payload }) => ({
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
  [GetToolRoutine.FULFILL]: (state, { payload }) => ({
    ...state,
    payload: {
      ...state.payload,
      [payload.id]: {
        ...state.payload[payload.id],
        status: STATUS.FETCHED
      }
    }
  }),
  [SetToolRoutine.SUCCESS]: (state, { payload }) => ({
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

const localState = state => state.tools;
export const selectItem = (state) => (id) => localState(state).payload[id];
export const selectItemByPermalink = (state) => (permalink) => selectItem(state)(localState(state).by_permalink[permalink]);
export const selectItems = (state) => mapToArray(localState(state).payload);
