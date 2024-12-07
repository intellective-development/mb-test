// @flow
import I18n from 'i18n-js';
import en from './en';

I18n.locale = 'en';
I18n.fallback = true;

// maintain any past I18n configuration (this is a workaround to support multiple I18n configs in one app)
// FIXME: pull this out when we've migrated libraries.
const prev_en = I18n.translations.en || {};
I18n.translations = {
  en: {
    ...prev_en,
    ...en
  }
};

export default I18n;
