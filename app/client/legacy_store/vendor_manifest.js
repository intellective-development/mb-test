window.Backbone = Backbone; // should be removable
window.$ = $; // required to make some libraries (like ahoy) work

//from minibar.js
import jquery_simulate from 'legacy_store/vendor/jquery.simulate'; // <-- necessary?
import jquery_validate from 'legacy_store/vendor/jquery.validate'; // attaches itself
import jquery_validate_additional from 'legacy_store/vendor/jquery.validate.additional';
import base64 from 'legacy_store/vendor/base64.js'; //polyfill, currently used by convert_utf8_b64, adds atob/btoa
window.base64 = base64;

import jquery_cookie from 'jquery.cookie'; //adds itself to jquery
import jquery_scrolltofixed from 'scrolltofixed'; //adds itself to jquery
require('imports-loader?$=jquery!legacy_store/vendor/jquery.payment'); // use commonjs syntax, since its stupid and needs jquery

// all of these files were changed so that their global "this" were replaced with "window"
import foundation from 'legacy_store/vendor/foundation/foundation';
import foundation_alerts from 'legacy_store/vendor/foundation/foundation.alerts';
import foundation_abide from 'legacy_store/vendor/foundation/foundation.abide';
import foundation_cookie from 'legacy_store/vendor/foundation/foundation.cookie';
import foundation_dropdown from 'legacy_store/vendor/foundation/foundation.dropdown';
import foundation_forms from 'legacy_store/vendor/foundation/foundation.forms';
import foundation_magellan from 'legacy_store/vendor/foundation/foundation.magellan'; // unused
import foundation_reveal from 'legacy_store/vendor/foundation/foundation.reveal';
import foundation_section from 'legacy_store/vendor/foundation/foundation.section';
import foundation_topbar from 'legacy_store/vendor/foundation/foundation.topbar';
import foundation_placeholder from 'legacy_store/vendor/foundation/foundation.placeholder';

// these need to be added to global scope
import Pace from 'pace-progress';
window.pace = Pace;
