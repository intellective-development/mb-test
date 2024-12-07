import variant_factory from './variant.factory';
import {
  formatVolumeShort
} from '../helpers';

describe('formatVolumeShort', () => {
  it('returns a formatted string variant\'s volume', () => {
    const variant = variant_factory.build();
    expect(formatVolumeShort(variant)).toEqual('6 pack 12oz');
  });
});
