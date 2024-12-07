// @flow

// This module provides a plain object to act as an interface with the various
// bits of static configuration data the server is injecting into the page.
// These are pulled with a set of standardized helpers that are intended to be enable
// environment safe access of said data.

// We should try to standardize on the communication medium we're using here.

export const getMetaContent = (name: string): ?string => {
  if (!global.document || !global.document.head) return null;

  const tag = global.document.head.querySelector(`meta[name=${name}]`);

  if (!tag) return null;

  return tag.content;
};

const getGlobalProperty = (attribute_name: string): ?string => {
  return global[attribute_name];
};

export default {
  csrf_token: getMetaContent('csrf-token'),
  initial_access_token: getMetaContent('access-token'),
  app_client_id: getGlobalProperty('ClientId'),
  app_client_secret: getGlobalProperty('ClientSecret'),
  google_analytics_id: getGlobalProperty('GoogleAnalyticsID')
};
