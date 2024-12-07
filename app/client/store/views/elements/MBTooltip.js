// @flow

import * as React from 'react';
import classNames from 'classnames';

const TOOLTIP_POINTER_LENGTH = 10;

type Orientation = 'top' | 'right' | 'bottom' | 'left';
type MBTooltipProps = {
  children: React.Node,
  default_orientation: Orientation,
  tooltip_text: string,
  tooltip_class_name?: string
};
type MBTooltipState = {
  orientation: Orientation
};

class MBTooltip extends React.Component<MBTooltipProps, MBTooltipState> {
  static defaultProps = {
    default_orientation: 'top'
  };
  trigger_ref: ?HTMLSpanElement
  tooltip_text_ref: ?HTMLSpanElement

  constructor(props: MBTooltipProps){
    super(props);
    this.state = {
      orientation: props.default_orientation
    };
  }

  determineOrientation = () => {
    if (!this.trigger_ref || !this.tooltip_text_ref) return null;

    const { default_orientation } = this.props;
    const trigger_bounds = this.trigger_ref.getBoundingClientRect();
    const tooltip_bounds = this.tooltip_text_ref.getBoundingClientRect();
    const trigger_middle_x_coord = (trigger_bounds.left + (trigger_bounds.width / 2));
    const trigger_middle_y_coord = (trigger_bounds.top + (trigger_bounds.height / 2));

    const vertical_tooltip_fits_top = ((trigger_bounds.top - tooltip_bounds.height - TOOLTIP_POINTER_LENGTH) > 0);
    const vertical_tooltip_fits_right = ((trigger_middle_x_coord + (tooltip_bounds.width / 2)) < window.innerWidth);
    const vertical_tooltip_fits_bottom = ((trigger_bounds.bottom + tooltip_bounds.height + TOOLTIP_POINTER_LENGTH) < window.innerHeight);
    const vertical_tooltip_fits_left = ((trigger_middle_x_coord - (tooltip_bounds.width / 2)) > 0);

    const horizontal_tooltip_fits_top = (trigger_middle_y_coord - (tooltip_bounds.height / 2) > 0);
    const horizontal_tooltip_fits_right = ((trigger_bounds.right + tooltip_bounds.width + TOOLTIP_POINTER_LENGTH) < window.innerWidth);
    const horizontal_tooltip_fits_bottom = (trigger_middle_y_coord + (tooltip_bounds.height / 2) < window.innerHeight);
    const horizontal_tooltip_fits_left = ((trigger_bounds.left - tooltip_bounds.width - TOOLTIP_POINTER_LENGTH) > 0);

    const tooltip_fits = {
      top: vertical_tooltip_fits_left &&
           vertical_tooltip_fits_top &&
           vertical_tooltip_fits_right,
      right: horizontal_tooltip_fits_top &&
             horizontal_tooltip_fits_right &&
             horizontal_tooltip_fits_bottom,
      bottom: vertical_tooltip_fits_left &&
              vertical_tooltip_fits_bottom &&
              vertical_tooltip_fits_right,
      left: horizontal_tooltip_fits_top &&
            horizontal_tooltip_fits_left &&
            horizontal_tooltip_fits_bottom
    };

    if (tooltip_fits[default_orientation]){
      this.setState({ orientation: default_orientation });
    } else if (tooltip_fits.top){
      this.setState({ orientation: 'top' });
    } else if (tooltip_fits.right){
      this.setState({ orientation: 'right' });
    } else if (tooltip_fits.bottom){
      this.setState({ orientation: 'bottom' });
    } else if (tooltip_fits.left){
      this.setState({ orientation: 'left' });
    } else {
      this.setState({ orientation: default_orientation });
    }
  }

  render(){
    const { tooltip_text, tooltip_class_name, children } = this.props;
    const tooltip_text_classes = classNames(
      'el-tooltip__text',
      tooltip_class_name,
      `el-tooltip__text--${this.state.orientation}`
    );
    return (
      <span
        ref={(trigger_el) => { this.trigger_ref = trigger_el; }}
        className="el-tooltip"
        onMouseOver={() => this.determineOrientation()}>
        {children}
        <span
          ref={(tooltip_text_el) => { this.tooltip_text_ref = tooltip_text_el; }}
          className={tooltip_text_classes}>
          {tooltip_text}
        </span>
      </span>
    );
  }
}

export default MBTooltip;
