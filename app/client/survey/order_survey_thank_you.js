import * as React from 'react';
import AppReviewRequest from './app_review_request';

const OrderSurveyThankYou = ({ score, referralReward, referralCode }) => (
  <div>
    <div className="checkout-frame no-bottom-margin">
      <div className="modal-header mega-header">
        <h3>Thank you for your feedback</h3>
        <AppReviewRequest score={score} />
      </div>
    </div>
    <div className="checkout-frame no-bottom-margin">
      <div className="modal-header mega-header">
        <h3>Share with friends</h3>
        <h2>Get free drinks for spreading the word about Minibar Delivery.</h2>
      </div>
      <div className="checkout-panel mega-body">
        <div className="row">
          <div className="large-5 medium-5 push-1 column">
            <p className="p-large large-10">
              Give ${referralReward}, get ${referralReward}, when they use your referral code on their first order.
            </p>
          </div>
          <div className="large-5 medium-5 pull-1 column">
            <ul className="actions">
              <li><span className="code-block">{referralCode}</span></li>
              <li><a className="button-v2 icon icon-twitter twitter" href={`https://twitter.com/home?status=Get%20$${referralReward}%20off%20wine,%20spirits%20and%20beer%20on%20your%20first%20@minibardelivery%20order.%20Use%20code:%20${referralCode}%20https://minibardelivery.com`} target="_blank" rel="noopener noreferrer">Tweet it out</a></li>
              <li><a className="button-v2 icon icon-facebook facebook" href="https://www.facebook.com/sharer/sharer.php?u=https://minibardelivery.com" target="_blank" rel="noopener noreferrer">Share on Facebook</a></li>
              <li><a className="button-v2 icon icon-email" href={`mailto:?Subject=Save%20%24${referralReward}%20on%20your%20first%20order%20from%20Minibar&Body=Hi%2C%0A%0AHere%27s%20a%20%24${referralReward}%20promo%20code%20for%20Minibar%2C%20the%20app%20that%20provides%20wine%2C%20spirits%20and%20beer%20delivered%20to%20your%20door%20in%20under%20an%20hour.%0A%0AMy%20personal%20code%20is%3A%20${referralCode}.%0A%0ATo%20use%20it%2C%20download%20Minibar%20Delivery%20from%20the%20app%20store%20here%3A%20http%3A//mbar.me/MNBjnv%20or%20visit%20the%20website%20minibardelivery.com.%0A%0AI%20get%20a%20%24${referralReward}%20credit%20when%20you%20use%20my%20code%20so%20let%27s%20both%20enjoy%20a%20drink%21%0A%0ACheers`} target="_blank" rel="noopener noreferrer">Email friends</a></li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    <div className="checkout-frame no-bottom-margin">
      <div className="modal-header mega-header">
        <h2>Go to <a href="/">minibardelivery.com</a></h2>
      </div>
    </div>
  </div>
);

export default OrderSurveyThankYou;
