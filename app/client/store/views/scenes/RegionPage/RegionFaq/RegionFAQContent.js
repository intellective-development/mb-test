export const getRegionFAQContent = ({ name, slug }) => {
  const regionsWithCustomAnswer = [
    'brooklyn',
    'dallas',
    'long-island',
    'new-york-city',
    'queens',
    'staten-island',
    'the-bronx'
  ];

  let lastAnswer = 'In most of our delivery markets, there is a $5 delivery fee applied to each order. These fees are in place to help our retail partners offset costs involved in the delivery of your order.';

  if (regionsWithCustomAnswer.indexOf(slug) > -1){
    lastAnswer = `In ${name}, most stores offer delivery for free. ${lastAnswer}`;
  }

  return [
    {
      answer: "Yes, alcohol delivery is legal in the cities and states Minibar Delivery serves. We've been helping local stores deliver wine, spirits, and beer for over five years!",
      question: 'Is alcohol delivery legal?'
    },
    {
      answer: 'In markets where tips are accepted, the order will default to a tip that you can easy edit or change during checkout to your desired amount.  You can also give the driver a cash tip if you would rather instead of adding it at checkout.  Drivers appreciate your tips and are a critital part of getting your orders delivered to you.',
      question: 'How can I tip my delivery driver?'
    },
    {
      answer: 'In most cases, deliveries take 30–60 minutes, but delivery times are subject to the stores themselves, and other variables such as time of day, order volume, and traffic conditions. The delivery expectation and delivery fees for each store are listed on the various product pages.',
      question: 'How long does delivery take?'
    },
    {
      answer: lastAnswer,
      question: 'Are there any fees for alcohol delivery?'
    }
  ];
};
