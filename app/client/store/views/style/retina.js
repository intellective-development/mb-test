import { isUndefined } from 'lodash-es';

const dppx = '(WebkitMinDevicePixelRatio: 2),(minResolution: 192dpi)';

export default (retina, normal) =>
  (isUndefined(normal)
    ? {
      [`@media ${dppx}`]: retina
    }
    : {
      [`@media ${dppx}`]: retina,
      [`@media not ${dppx}`]: normal
    });
