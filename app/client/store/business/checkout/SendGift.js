import React, { useState, useCallback } from 'react';

// TODO: animate

const SendGift = () => {
  const [isGift, setIsGift] = useState(false);
  const isGiftClicked = useCallback(e => {
    setIsGift(e.nativeEvent.target.checked);
  }, []);

  return (
    <div>
      <label htmlFor="is_gift">
        <input type="checkbox" id="is_gift" onChange={isGiftClicked} />
        <h2 style={{
          display: 'inline',
          fontSize: '14px',
          fontWeight: 'normal',
          textTransform: 'uppercase',
          letterSpacing: '1px !important',
          fontFamily: 'Avenir, "Avenir-Custom", "Avenir-Local", "Helvetica Neue", Helvetica, Arial, sans-serif'
        }}>&nbsp;Send as a Gift (Free)&nbsp;</h2>
        <span className="assistive">&nbsp;With personalized note &amp; gift receipt</span>
      </label>
      { isGift ?
        <p id="gift-message" className="">
          <input id="gift_recipient" type="text" maxLength="100" placeholder="Recipient Name" value="" />
          <input id="gift_recipient_phone" type="text" maxLength="100" placeholder="Recipient Phone Number" value="" />
          <textarea maxLength="200" id="gift_message" placeholder="Enter gift note" />
          <small>
            <span id="gift-message_chars-left">200</span> characters left.
          </small>
          <br />
          <span className="assistive">
            Alcohol deliveries must be received by someone over 21 years of age, they cannot be left in a mailbox.
            The store may reach out to the gift recipient to co-ordinate delivery if a scheduled delivery time has not been provided.
            Note: Beer and oversized items may not come gift wrapped.
          </span>
        </p> : null }
    </div>
  );
};

export default SendGift;
