import { useCallback, useLayoutEffect, useState } from 'react';

export const useBounds = () => {
  /* let bounds = { bottom, height, left, right, top, width, x, y } */
  const [bounds, setBounds] = useState({});
  const [node, setNode] = useState(null);

  const ref = useCallback((currentNode) => {
    setNode(currentNode);
  }, []);

  useLayoutEffect(() => {
    if (node){
      const getBounds = () =>
        window.requestAnimationFrame(() =>
          setBounds(node.getBoundingClientRect().toJSON()));

      getBounds();

      window.addEventListener('resize', getBounds);
      window.addEventListener('scroll', getBounds);

      return () => {
        window.removeEventListener('resize', getBounds);
        window.removeEventListener('scroll', getBounds);
      };
    }
  }, [node]);

  return { node, ref, ...bounds };
};
