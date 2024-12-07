// @flow

import * as React from 'react';
import OverlayModal from 'react-overlays/lib/Modal';
import bindClassNames from '../../../shared/utils/bind_classnames';
import MBIcon from './MBIcon';
import * as MBText from './MBText';
import styles from './MBModal.scss';

const cn = bindClassNames(styles);

// This module exports a reactive modal and a subcomponents.
// The idea is to provide a new baseline for us to work off of as we move towards component style sharing.
// Eventually, the goal is to fit this component and its props into the styleguide the design team is working towards.

const MODAL_SIZE_CLASSES = {
  tiny: 'elMBModal_Content__Tiny',
  small: 'elMBModal_Content__Small',
  medium: 'elMBModal_Content__Medium',
  large: 'elMBModal_Content__Large'
};

type MBModalProps = {
  children: React.Node,
  onHide?: Function,
  show: boolean,
  size: 'tiny' | 'small' | 'medium' | 'large',
  modalClassName?: string
}
export class Modal extends React.Component<MBModalProps> {
  static defaultProps = {size: 'large'};

  preventHide = (event: SyntheticInputEvent<*>) => {
    event.stopPropagation();
  }

  render(){
    const { size, modalClassName, show, onHide, children } = this.props;
    const classes = cn('elMBModal_Content', MODAL_SIZE_CLASSES[size], modalClassName);

    return (
      <OverlayModal
        backdropClassName={cn('elMBModal_Backdrop')}
        show={show}
        onHide={onHide} >
        <div className={cn('elMBModal_Wrapper')} onClick={onHide}>
          <div className={classes} onClick={this.preventHide}>
            {children}
          </div>
        </div>
      </OverlayModal>
    );
  }
}

type SectionHeaderProps = {className?: string, top?: boolean, children?: React.Node, renderLeft?: () => React.Node, renderRight?: () => React.Node};
export const SectionHeader = ({className, top = true, children, renderLeft = SectionHeaderFiller, renderRight = SectionHeaderFiller}: SectionHeaderProps) => {
  const classes = cn('elMBModal_SectionHeader', className, {
    elMBModal_SectionHeader_Top: top
  });

  return (
    <div className={classes}>
      {renderLeft()}
      <MBText.H4 className={cn('elMBModal_SectionHeaderText')}>{children}</MBText.H4>
      {renderRight()}
    </div>
  );
};

const SectionHeaderFiller = () => <div className={cn('elMBModal_SectionHeader_Filler')} />;

type CloseProps = {onClick?: Function};
export const Close = ({onClick}: CloseProps) => (
  <div className={cn('elMBModal_Close')} onClick={onClick} aria-label="Close">
    <MBIcon name="close" />
  </div>
);

type BackProps = {onClick?: Function};
export const Back = ({onClick}: BackProps) => (
  <div className={cn('elMBModal_Back')} onClick={onClick} aria-label="Back">
    <MBIcon name="back" />
    <MBText.Span className={cn('elMBModal_BackText')}>&nbsp;Back</MBText.Span>
  </div>
);
