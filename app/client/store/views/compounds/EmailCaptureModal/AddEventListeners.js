// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import { email_capture_actions, email_capture_selectors } from 'store/business/email_capture';
import { INPUT_ID } from 'store/views/compounds/AddressEntry';
import { EMAIL_CAPTURE_SECTION_ID } from 'store/views/scenes/LandingPage/EmailCapture';
import { APP_STORE_LINK_ID, PLAY_STORE_LINK_ID } from 'store/views/elements/MBAppStoreLink';

const isElementVisible = (selector: string) => () => {
  const element = document.querySelector(selector);
  const min_height = window.innerHeight;
  const element_bottom = element.getBoundingClientRect().bottom;

  return element_bottom < min_height;
};

type Listener = {
  name: string,
  event: string,
  // We'll either use your selector string to get an element list, or you can provide your own function
  // This is needed for things like selecting the window, which doesn't work in document.querySelect
  selector: string | () => Element[],
  shouldTrigger?: () => boolean
}

const LISTENTER_CONFIG: Listener[] = [
  {
    name: 'click app store button',
    event: 'click',
    selector: `#${APP_STORE_LINK_ID}`
  }, {
    name: 'click play store button',
    event: 'click',
    selector: `#${PLAY_STORE_LINK_ID}`
  }, {
    name: 'click on address input',
    event: 'click', // Ideally this would be on change, but that event doesn't fire until blur; I think it's swallowed by react.
    selector: `#${INPUT_ID}`
  }, {
    name: 'type in address input',
    event: 'keypress', // Ideally this would be on change, but that event doesn't fire until blur; I think it's swallowed by react.
    selector: `#${INPUT_ID}`
  }, {
    name: 'focus email section input',
    event: 'focus',
    selector: `#${EMAIL_CAPTURE_SECTION_ID}`
  }, {
    name: 'scroll email section into view',
    event: 'scroll',
    selector: () => [window],
    shouldTrigger: isElementVisible(`#${EMAIL_CAPTURE_SECTION_ID}`)
  }
];

type Props = {
  should_show: boolean,
  preventModal(): void
}

class AddEventListeners extends React.Component<Props> {
  active_listeners: Array<{ element: Element, event: string, callback(): void }> = []

  componentDidMount(){ this.addListeners(); }
  componentWillReceiveProps(nextprops){
    if (this.props.should_show && !nextprops.should_show){
      this.removeListeners();
    }
  }
  componentWillUnmount(){ this.removeListeners(); }

  addListeners = () => {
    LISTENTER_CONFIG.forEach(({ name, event, selector, shouldTrigger }) => {
      const elements_to_watch = (
        typeof selector === 'string'
          ? Array.from(document.querySelectorAll(selector))
          : selector()
      );

      elements_to_watch.forEach(element => {
        const callback = this.preventModal.bind(this, name, shouldTrigger);
        element.addEventListener(event, callback);
        this.active_listeners.push({ element, event, callback });
      });
    });
  }

  removeListeners = () => {
    this.active_listeners.forEach(({ element, event, callback }) => {
      element.removeEventListener(event, callback);
    });
  }

  preventModal = (name: string, shouldTrigger?: () => boolean) => {
    const { should_show, preventModal } = this.props;

    if (!should_show){ return; }
    if (shouldTrigger && !shouldTrigger()){ return; }

    preventModal(name);
  }

  render(){
    return null;
  }
}

const AddEventListenersSTP = (state) => ({
  should_show: email_capture_selectors.shouldShowModal(state)
});

const AddEventListenersDTP = {
  preventModal: email_capture_actions.preventModal
};

export default connect(AddEventListenersSTP, AddEventListenersDTP)(AddEventListeners);
