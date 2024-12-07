
import { makeMBRequest } from '@minibar/store-business/src/networking/mb_api_helpers';
import { buildExternalUrl } from '@minibar/store-business/src/networking/helpers';

const fetch_settings_path = 'settings';
const getBaseUrl = () => '/api/partners/v2';

export const fetchWorkingHours = () => {
  const url = buildExternalUrl(getBaseUrl)(fetch_settings_path);
  const request_prom = makeMBRequest(url);
  return request_prom;
};
