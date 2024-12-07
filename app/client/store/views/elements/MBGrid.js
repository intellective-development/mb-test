// @flow
import * as React from 'react';
import cn from 'classnames';

// This component is intended to expose a basic flex-based block grid.
// For simple components which make use of our default breakpoints, it should be sufficient
// More complex layouts will likely require a more bespoke implementation, and can use the underlying sass mixins.

// Similarly to other grid systems, the size classes flow upwards. Specifying only `cols` will apply that layout to all screen sizes,
// `cols` and `medium_cols` will apply the medium cols to medium and large screens, and large will only apply to large screens

type MBGridProps = {cols: number, medium_cols?: number, large_cols?: number, className?: string, };
const MBGrid = ({cols, medium_cols, large_cols, className, ...input_props}: MBGridProps) => {
  const classes = cn(
    'el-mbgrid',
    defaultClass(cols),
    mediumClass(medium_cols),
    largeClass(large_cols),
    className
  );
  return <ul {...input_props} className={classes} />;
};

const defaultClass = (cols: number) => (cols ? `el-mbgrid--${cols}` : '');
const mediumClass = (cols: ?number) => (cols ? `el-mbgrid--${cols}--medium` : '');
const largeClass = (cols: ?number) => (cols ? `el-mbgrid--${cols}--large` : '');

export const MBGridElement = (props: any) => (<li {...props} />);
MBGrid.Element = MBGridElement;

export default MBGrid;
