// @flow

export const hideModal = (target) => ({
  type: 'EMAIL_CAPTURE:HIDE_EMAIL_CAPTURE_MODAL',
  meta: { analytics: { target } }
});

export const showModal = () => ({
  type: 'EMAIL_CAPTURE:SHOW_EMAIL_CAPTURE_MODAL'
});

export const shouldShowModal = () => ({
  type: 'EMAIL_CAPTURE:SHOULD_SHOW_EMAIL_CAPTURE_MODAL'
});

export const preventModal = (target?: string) => ({
  type: 'EMAIL_CAPTURE:PREVENT_EMAIL_CAPTURE_MODAL',
  meta: { analytics: { target } }
});

type EmailCaptureParams = {
  email: string,
  target?: string
}

export const addEmail = ({ email, target }: EmailCaptureParams) => ({
  type: 'EMAIL_CAPTURE:ADD_EMAIL',
  payload: { email },
  meta: {
    analytics: {
      target
    }
  }
});

export const copyCoupon = (coupon_code: string) => ({
  type: 'EMAIL_CAPTURE:COPY_COUPON',
  payload: { coupon_code }
});
