
import deliveryCost from '../deliveryCost';

describe('deliveryCost', () => {
  it('renders an icon when ShopRunner is available', () => {
    expect(deliveryCost(true, null)).toMatchSnapshot();
  });

  it('renders an icon with specific styling when ShopRunner is available', () => {
    expect(deliveryCost(true, null, 'shoprunner__container_inline')).toMatchSnapshot();
  });

  it('renders fallback cost when ShopRunner is not available', () => {
    expect(deliveryCost(false, 'fallback')).toMatchSnapshot();
  });
});
