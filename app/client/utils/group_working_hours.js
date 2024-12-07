import _ from 'lodash';

const groupWorkingHours = (hours) => {
  let workingHours = hours;
  const groupedWorkingHours = [];
  const wdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  workingHours = _.sortBy(workingHours, ['wday']);
  workingHours.push(workingHours.shift()); //this puts Sunday to last place
  _.compact(workingHours).forEach((workingHour, i) => {
    // check if in sequence
    if (i !== 0 && (workingHour.starts_at === workingHours[i - 1].starts_at && workingHour.ends_at === workingHours[i - 1].ends_at)){
      groupedWorkingHours[groupedWorkingHours.length - 1].endDay = wdays[workingHour.wday];
    } else {
      groupedWorkingHours.push({ startDay: wdays[workingHour.wday], endDay: wdays[workingHour.wday], startsAt: workingHour.starts_at, endsAt: workingHour.ends_at });
    }
  });
  return groupedWorkingHours;
};
export default groupWorkingHours;
