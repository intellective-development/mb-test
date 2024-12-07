import moment from 'moment';

const date_format_string = 'dddd, MMM D'; // Friday, Jul 9
export const formatDate = (datetime) => {
  const today = moment().startOf('day');
  const tomorrow = today.clone().add(1, 'days');

  let formatted_date = moment(datetime).format(date_format_string);
  if (moment(datetime).isSame(today, 'day')){ // <todays date> -> Today
    formatted_date = 'Today';
  } else if (moment(datetime).isSame(tomorrow, 'day')){
    formatted_date = 'Tomorrow';
  }

  return formatted_date;
};

const time_format_string = 'h:mma'; // 12:00am
export const formatTime = (datetime, truncate_zeroes = false) => {
  const remove_zero_regex = /(\d{1,2}):00(am|pm)/i;
  let formatted_time = moment.parseZone(datetime).format(time_format_string);

  if (/12:00am/i.test(formatted_time)){ // 12:00am -> midnight
    formatted_time = 'midnight';
  } else if (/12:00pm/i.test(formatted_time)){ // 12:00pm -> noon
    formatted_time = 'noon';
  } else if (truncate_zeroes && remove_zero_regex.test(formatted_time)){ // 1:00pm -> 1pm
    formatted_time = remove_zero_regex.exec(formatted_time).slice(1).join('');
  }
  return formatted_time;
};
