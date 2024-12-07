// @flow

import 'shared/polyfills';
import apiAuthenticate from './shared/web_authentication';
import initBranch from './shared/branch';
import initRaven from './shared/raven';
import initModuleLinks from './shared/utils/init_module_links';
import { initLogrocket } from './logrocket';
import hydrateReactComponents from './shared/utils/hydrate_react_components';

import Navigation from './store/views/compounds/Navigation';
import EmailCaptureModal from './store/views/compounds/EmailCaptureModal';
import AddressExplanation from './store/views/compounds/AddressExplanation';
import {
  AppInstall as LandingAppInstall,
  EmailCapture as LandingEmailCapture,
  LandingHero
} from './store/views/scenes/LandingPage';
import StoreEntry from './store/views/compounds/StoreEntry';
import ProductScroller from './store/views/compounds/ProductScroller';
import PressPage from './press_page/app';
import PernodRicardWinter from './pernod_ricard_winter/app';
import Login from './store/business/login/Login';
import ForgotPassword from './store/business/login/ForgotPassword';
import { RegionPage } from './store/views/scenes/RegionPage/RegionPage';
import Signup from './store/business/login/Signup';

const hydrateHompage = hydrateReactComponents({
  LandingHero,
  Navigation,
  StoreEntry,
  LandingAppInstall,
  LandingEmailCapture,
  Login,
  ForgotPassword,
  Signup,
  EmailCaptureModal,
  PressPage,
  ProductScroller,
  PernodRicardWinter,
  RegionPage,
  AddressExplanation
});

initBranch();
initRaven();
apiAuthenticate();
initLogrocket();

// spin up app
$(document).ready(() => {
  initModuleLinks(); // TODO: deprecated, only used on the bartenders page
  hydrateHompage();
});

// enable hot reloading
if (module.hot){
  // TODO: this could be made more efficient by only hydrating the relevant component
  module.hot.accept('./store/views/compounds/Navigation', hydrateHompage);
  module.hot.accept('./store/views/compounds/StoreEntry', hydrateHompage);
  module.hot.accept('./store/views/scenes/LandingPage', hydrateHompage);
  module.hot.accept('./store/views/compounds/EmailCaptureModal', hydrateHompage);
}
