import * as React from 'react';

const AppReviewRequest = ({score}) => {
  if (score !== 5){
    return (null);
  }
  return (
    <div>
      <a href="https://itunes.apple.com/us/app/minibar-delivery-wine-liquor/id720850888?mt=8&uo=4&at=11l5XB&ct=minibar">Review our app and help spread the word.</a>
    </div>
  );
};

export default AppReviewRequest;
