import { css } from '@amory/style/umd/style';
import React, { useState, useCallback, useEffect, useRef } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import ReactDOM from 'react-dom';
import { isObject, map } from 'lodash';
import { Link } from 'react-router-dom';
import AlertBox from 'shared/components/alert_box';
import { SetModalOpen } from 'modules/checkout/checkout.actions';
import { selectIsModalOpen, selectModal } from 'modules/checkout/checkout.selectors';
import fonts from './MBElements/MBFonts.css.json';
import styles from '../Checkout.css.json';

export const Labeled = ({
  children,
  id,
  isRequired,
  label,
  labelStyle = {},
  meta = {},
  name,
  placeholder,
  style = {},
  ...props
}) => {
  const hasError = !meta.active && meta.error && meta.touched;
  const title = label || placeholder;

  return (
    <div className={css([styles.field, style])}>
      {label
        ? (
          <label
            className={css([
              styles.label,
              hasError ? styles.error : {},
              isRequired && !hasError ? styles.required : {},
              labelStyle
            ])}
            htmlFor={id || name || title}
            {...props}>
            {hasError
              ? (
                <span className={css(style.error)}>
                  {meta.error}
                </span>
              )
              : title
            }
          </label>
        )
        : null
      }
      {children}
    </div>
  );
};

export const Error = ({ meta }) => {
  const hasError = !meta.active && meta.touched && meta.error;
  if (!hasError){
    return null;
  }
  return (
    <span className={css(styles.error)}>
      {meta.error}
    </span>
  );
};

export const Input = ({
  children,
  id,
  input,
  inputStyle = {},
  isRequired,
  label,
  labelStyle = {},
  meta = {},
  placeholder,
  size,
  style,
  type = 'text',
  ...props
}) => {
  const hasError = !meta.active && meta.touched && meta.error;
  return (
    <Labeled
      id={id}
      isRequired={isRequired}
      label={label}
      labelStyle={labelStyle}
      meta={meta}
      name={name}
      placeholder={placeholder}
      style={style}>
      <input
        {...input}
        className={css([
          fonts.common,
          styles.input,
          hasError ? styles.error : {},
          inputStyle
        ])}
        id={id || name || label || props.placeholder}
        placeholder={placeholder}
        size={size}
        type={type}
        {...props} />
      {children}
    </Labeled>
  );
};

export const Textarea = ({
  cols = 65,
  id,
  input,
  inputStyle = {},
  isRequired,
  label,
  labelStyle = {},
  meta = {},
  placeholder,
  rows = 5,
  style = {},
  ...props
}) => {
  const remainingLength = props.maxLength ? props.maxLength - (input.value || '').length : undefined;
  return (
    <Labeled
      id={id}
      isRequired={isRequired}
      label={label}
      labelStyle={labelStyle}
      meta={meta}
      name={name}
      placeholder={placeholder}
      style={style}>
      <textarea
        className={css([
          fonts.common,
          styles.input,
          styles.textarea,
          inputStyle
        ])}
        cols={cols}
        id={id || name || label || placeholder}
        placeholder={placeholder}
        rows={rows}
        {...input}
        {...props} />
      {props.maxLength && (
        <div id="gift-message_chars-left"><small>{remainingLength} character{remainingLength !== 1 ? 's' : ''} left.</small></div>
      )}
    </Labeled>
  );
};

export const Checkbox = ({
  inputStyle,
  ...props
}) => (
  <Input
    inputStyle={{
      ...styles.checkbox,
      ...inputStyle
    }}
    style={{
      display: 'inline-block',
      minHeight: 20,
      minWidth: 20,
      padding: 0
    }}
    type="checkbox"
    {...props} />
);

export const Radio = () => (
  <React.Fragment>
    Delivery Address
    <span
      style={{
        display: 'flex',
        flex: 1,
        justifyContent: 'flex-end'
      }}>
      <label
        style={{ marginRight: 10 }}>
        <input
          checked="checked"
          className="radio-address_type"
          id="address_type_residential"
          name="address_type"
          type="radio"
          value="residential" />
        Residential
      </label>
      <label>
        <input
          className="radio-address_type"
          id="address_type_business"
          name="address_type"
          type="radio"
          value="business" />
        Business
      </label>
    </span>
  </React.Fragment>
);

const Option = ({
  label,
  onClick,
  selected,
  value,
  ...props
}) => {
  const onClickCallback = useCallback(e => {
    e.stopPropagation();
    onClick(value);
  }, [onClick, value]);
  // TODO: hover and outline
  // TOOD: aria

  return (
    <div
      aria-selected={selected}
      onClick={onClickCallback}
      role="option"
      style={{
        outline: 'none',
        cursor: 'pointer',
        padding: '12px 6px'
      }}
      tabIndex="0"
      {...props}>
      {label}
    </div>
  );
};

export const Select = ({
  containerStyle,
  defaultValue,
  disabled,
  disabledStyle,
  onSelect,
  options = []
}) => {
  const containerRef = useRef(null);

  const [selectedValue, setValue] = useState(defaultValue || options[0]);
  const [open, setOpen] = useState(false);

  const outsideClickListener = e => {
    const container = ReactDOM.findDOMNode(containerRef.current);
    if (container && e.target instanceof Node && !container.contains(e.target)){
      setOpen(false);
    }
  };
  useEffect(() => {
    document.addEventListener('click', outsideClickListener, true);
    return () => document.removeEventListener('click', outsideClickListener, true);
  });
  const _disabledStyle = disabled ? { backgroundColor: 'lightgrey' } : {};

  return (
    <div
      onClick={() => setOpen(false)}
      ref={containerRef}
      role="listbox"
      style={{
        background: 'url("/assets/arrow_down_grey.png") no-repeat 97.5% 50%',
        backgroundSize: 26,
        border: '1px solid #ccc',
        borderRadius: '3px',
        color: '#757575',
        flex: 1,
        fontFamily: '"Avenir-Custom", Avenir, Helvetica, sans-serif',
        fontSize: 15,
        height: 40,
        outline: 'none',
        position: 'relative',
        ...containerStyle,
        ..._disabledStyle,
        ...disabledStyle
      }}
      tabIndex="0">
      {open
        ? (
          <div
            style={{
              backgroundColor: 'white',
              border: 'solid 1px #757575',
              position: 'absolute',
              width: '100%',
              zIndex: 1
            }}>
            {map(options, item => {
              return (
                <Option
                  key={item.value}
                  label={item.label}
                  onClick={() => {
                    setOpen(false);
                    onSelect(item);
                    setValue(item);
                  }}
                  selected={selectedValue === item.value} />
              );
            })}
          </div>
        )
        : (
          <Option
            label={isObject(selectedValue)
              ? selectedValue.label
              : selectedValue
            }
            onClick={() => setOpen(true)} />
        )
      }
    </div>
  );
};

export const Row = ({
  style,
  ...props
}) => (
  <div
    style={{
      alignItems: 'center',
      display: 'flex',
      ...style
    }}
    {...props} />
);

export const Panel = ({
  children,
  style,
  title,
  ...props
}) => {
  return (
    <div
      style={{
        background: 'white',
        borderColor: '#e6e6e6',
        borderRadius: 0,
        borderStyle: 'solid',
        borderWidth: 1,
        marginBottom: '25px',
        padding: 0,
        position: 'relative',
        ...style
      }}>
      <h2
        style={{
          display: 'flex',
          fontFamily: '"Avenir-Heavy", "Avenir-Local", Avenir, "Helvetica Neue", Helvetica, Arial, sans-serif',
          fontSize: '15px',
          fontWeight: 'bold',
          letterSpacing: 2,
          margin: 0,
          padding: 18,
          paddingBottom: 6,
          textTransform: 'uppercase'
        }}
        {...props}>
        {title}
      </h2>
      <div
        style={{
          background: 'white',
          border: '0 none #fff',
          borderColor: '#e6e6e6',
          borderRadius: 0,
          borderStyle: 'solid',
          borderWidth: 1,
          padding: '0 18px 18px'
        }}>
        {children}
      </div>
    </div>
  );
};

export const CheckoutColumn = ({
  children,
  style,
  ...props
}) => {
  return (
    <div
      style={{
        flex: 1,
        margin: '0 20px',
        marginBottom: 20,
        maxWidth: 480,
        minWidth: 320,
        ...style
      }}
      {...props}>
      {children}
    </div>
  );
};

export const CheckoutBody = ({
  children,
  style = {},
  ...props
}) => {
  return (
    <div
      className={css([
        styles.checkout,
        style
      ])}
      {...props}>
      {children}
    </div>
  );
};

export const Header = ({ children }) => (
  <div className="cmDNav_FullScreenWrapper" style={{ display: 'block' }}>
    <div className="el-mblayouts-sg cmDNav_ContainerCheckout">
      <Link to="/store/" id="logo" title="Minibar Delivery" className="cmDNav_NavLogo_Container">
        <img alt="minibar_logo" className="el-mbicon--minibar_logo cmDNav_NavLogo" src="/assets/components/elements/mb-icon/minibar_logo.png" srcSet="/assets/components/elements/mb-icon/minibar_logo@2x.png 2x, /assets/components/elements/mb-icon/minibar_logo@3x.png 3x" />
      </Link>
      {children}
    </div>
  </div>
);

export const ProgressBar = () => (
  <Header>
    <div className="cmCheckoutBreadcrumbs_Wrapper">
      <div className="cmCheckoutBreadcrumbs_ContentContainer">
        <div
          className="cmCheckoutBreadcrumbs_BarContainer"
          style={{
            width: 200,
            backgroundColor: '#e6e6e6',
            height: 4,
            marginLeft: 100,
            marginRight: 100
          }}>
          <div className="cmCheckoutBreadcrumbs_Bar cmCheckoutBreadcrumbs_Bar__sign-in" />
        </div>
        <div className="cmCheckoutBreadcrumbs_StepContainer">
          <div className="cmCheckoutBreadcrumbs_Step cmCheckoutBreadcrumbs_Step__Completed">
            <div
              style={{
                backgroundColor: '#222',
                width: 22,
                height: 22
              }}
              className="cmCheckoutBreadcrumbs_Step_Pip">
              <div style={{
                backgroundColor: '#fff',
                content: ' ',
                width: 10,
                height: 10,
                display: 'block',
                borderRadius: 10,
                marginLeft: 6,
                marginTop: 6
              }} />
            </div>
            <span className="elMBText elMBText_ResetSpacing">Information</span>
          </div>
          <div className="cmCheckoutBreadcrumbs_Step">
            <div
              style={{
                backgroundColor: '#e6e6e6',
                width: 22,
                height: 22
              }}
              className="cmCheckoutBreadcrumbs_Step_Pip">
              <div style={{
                backgroundColor: '#fff',
                content: ' ',
                width: 10,
                height: 10,
                display: 'block',
                borderRadius: 10,
                marginLeft: 6,
                marginTop: 6
              }} />
            </div>
            <span className="elMBText elMBText_ResetSpacing">Complete purchase</span>
          </div>
        </div>
      </div>
    </div>
  </Header>
);

export const SecurePayments = ({
  children
}) => (
  <React.Fragment>
    <img
      alt="secure payments icon"
      className="padlock-icon"
      src="/assets/padlock_icon.png"
      style={{ height: 14, width: 10 }} />
    <label
      htmlFor="same_as_shipping"
      style={{
        color: '#9b9b9b',
        display: 'inline',
        fontFamily: 'Avenir',
        fontSize: 14,
        fontWeight: 200
      }}>
      100% SECURE PAYMENTS {children}
    </label>
  </React.Fragment>
);

export const Divider = () => (
  <div
    style={{ borderTop: 'solid 1px grey' }} />
);

export const EditButton = ({
  style,
  ...props
}) => (
  <button
    style={{
      backgroundColor: 'transparent',
      border: 'none',
      color: 'gray',
      /* show a hand cursor on hover; some argue that we
      should keep the default arrow cursor for buttons */
      cursor: 'pointer',
      font: 'inherit',
      fontSize: 12,
      padding: 0,
      position: 'absolute',
      right: 20,
      top: 20,
      ...style
    }}
    {...props} />
);

export const CheckoutModal = () => {
  const isShown = useSelector(selectIsModalOpen);
  const {
    title,
    message
  } = useSelector(selectModal);
  const dispatch = useDispatch();
  return (
    <AlertBox
      title={title}
      message={message}
      show={isShown}
      onHide={() => { dispatch(SetModalOpen({})); }}
      error_cta="Ok" />
  );
};

export const RoundCheckBox = ({ name, value = false, onChange = () => {}, size = 14, ...props }) => {
  return (
    <div style={{
      position: 'relative',
      width: size,
      height: size
    }}>
      <label
        htmlFor={name}
        style={{
          backgroundColor: value ? 'rgb(76, 135, 246)' : 'transparent',
          border: value ? 'none' : '1px solid #ccc',
          position: 'absolute',
          borderRadius: '50%',
          cursor: 'pointer',
          height: size,
          width: size,
          left: 0,
          top: 0
        }}>
        <div
          style={{
            transform: 'rotate(-45deg)',
            border: '1px solid #fff',
            position: 'absolute',
            borderRight: 'none',
            borderTop: 'none',
            height: size / 4,
            width: (size / 2) + 1,
            left: Math.floor(size / 4),
            top: (size / 4),
            opacity: 1
          }} />
        <input
          type="checkbox"
          name={name}
          value={value}
          onChange={e => onChange(e.target.checked)}
          style={{ visibility: 'hidden' }}
          {...props} />
      </label>
    </div>
  );
};
