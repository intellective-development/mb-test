export const isIOS = jest.fn();
export const isAndroid = jest.fn();
export const isMobile = jest.fn();

export const __clearMocks__ = () => {
  isIOS.mockClear();
  isAndroid.mockClear();
  isMobile.mockClear();
};
