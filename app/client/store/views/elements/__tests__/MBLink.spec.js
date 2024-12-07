
import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import MBLink from '../MBLink';

describe('MBLink.Text', () => {
  it('renders', () => {
    expect(render(<BrowserRouter>
      <MBLink.Text href="store/category/wine">
        Click me!
      </MBLink.Text>
    </BrowserRouter>)).toMatchSnapshot();
  });
});

describe('MBLink.View', () => {
  it('renders', () => {
    expect(render(<BrowserRouter>
      <MBLink.View href="store/category/wine">
        <div>Click Me</div>
      </MBLink.View>
    </BrowserRouter>)).toMatchSnapshot();
  });
});
