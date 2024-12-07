
// based on  https://stackoverflow.com/a/16427747/3043447

// TODO: default export the function, use that instead
const TEST_KEY = 'test';
export const testLS = () => {
  try {
    localStorage.setItem(TEST_KEY, TEST_KEY);
    localStorage.removeItem(TEST_KEY);
    return true;
  } catch (_e){
    return false;
  }
};

// these will not change during the course of a session
export default testLS(); // DEPRECATED: use the function export instead
