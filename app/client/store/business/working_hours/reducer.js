// @flow
type WorkingHours = {
  working_hours: Array<Object>
}

export const workingHoursReducer = (state: working_hours_reducer = {}, action: Action) => {
  switch (action.type){
    case 'WORKING_HOURS:FETCH__SUCCESS':
      return {...state, ...(action.payload.settings || {})};
    default:
      return state;
  }
};

export type LocalState = {
  settings_reducer: WorkingHours
};

export default workingHoursReducer;
