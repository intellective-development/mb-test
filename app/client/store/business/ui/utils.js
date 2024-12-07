// @flow

export const enterStore = (initial_destination: string = '/store') => {
  let formatted_destination = initial_destination;
  if (formatted_destination.substr(0, 1) !== '/'){ // append to root
    formatted_destination = `/${formatted_destination}`;
  }

  const prefix = '/store'; // formatted_destination will now always have a leading slash, don't need trailing here
  // if formatted_destination doesn't start with /store, prepend it. for promos
  if (formatted_destination.substr(0, prefix.length) !== prefix){
    formatted_destination = prefix + formatted_destination;
  }

  window.location.href = formatted_destination.toLowerCase();
};
