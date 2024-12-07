import * as React from 'react';
import Carousel from '../carousel/carousel';

const delay = 5000;

const App = () => (
  <div>
    <Carousel delay={delay}>
      <div>
        <h5>
          {'I loved absolutely everything about this app! It was user friendly, super convenient, and the service was excellent!'}
        </h5>
      </div>
      <div>
        <h5>{'No reason to lug around heavy bottles anymore, just Minibar it.'}</h5>
      </div>
      <div>
        <h5>{'Best app ever!! It\'s easy and saves so much time. Perfect for every occasion'}</h5>
      </div>
    </Carousel>
  </div>
);

export default App;
