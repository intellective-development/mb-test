import * as React from 'react';
import ReasonSelector from '../reason_selector';

describe('ReasonSelector', () => {
  const reasons = [
    {id: 1, name: 'tasted bad'},
    {id: 2, name: 'late delivery'}
  ];

  it('renders', () => {
    expect(render(
      <ReasonSelector
        reasons={reasons}
        hidden="false"
        reasonClicked={jest.fn()}
        selectedReasons={[reasons[1]]} />
    )).toMatchSnapshot();
  });

  it('Uses callback to update state when reason is selected', () => {
    const clickReason = jest.fn();
    const component = mount(
      <ReasonSelector
        reasons={reasons}
        hidden="false"
        reasonClicked={clickReason}
        selectedReasons={[]} />
    );

    component.find('.reason').last().simulate('click');
    expect(clickReason).toHaveBeenCalled(); // note that the component hasn't changed, because it doesn't hold the selected state
  });
});
