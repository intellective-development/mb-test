import { useState } from 'react';

export const useToggle = (initial = false) => {
  const [toggle, setToggle] = useState(initial);
  const handleToggle = () => setToggle((state) => !state);

  return [toggle, handleToggle];
};
