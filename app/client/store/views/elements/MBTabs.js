// @flow

import * as React from 'react';

const MBTab = ({
  children,
  className,
  label,
  onClick,
  onTabClick,
  selected,
  ...props
}) => {
  const isActive = label === selected;

  return (
    <div
      aria-controls={`${label}-panel`}
      aria-selected={isActive ? 'true' : 'false'}
      className={className}
      id={`${label}-tab`}
      key={`${label}-tab`}
      onClick={(e) => {
        if (onClick){
          onClick(e);
        }
        onTabClick && onTabClick(label);
      }}
      role="tab"
      tabIndex={isActive ? 0 : -1}
      {...props}>
      {children}
    </div>
  );
};

MBTab.displayName = 'MBTab';

const MBTablist = ({
  children, className, label, ...props
}) => (
  <div aria-label={label} className={className} role="tablist" {...props}>
    {children}
  </div>
);

MBTablist.displayName = 'MBTablist';

const MBTabpanel = ({
  children,
  className,
  label,
  selected,
  ...props
}) => {
  const isActive = label === selected;

  return (
    <div
      aria-hidden={isActive ? 'false' : 'true'}
      aria-labelledby={`${label}-tab`}
      className={className}
      id={`${label}-panel`}
      role="tabpanel"
      tabIndex={0}
      {...props}>
      {children}
    </div>
  );
};

MBTabpanel.displayName = 'MBTabpanel';

class MBTabs extends React.Component {
  constructor(props){
    super(props);

    this.state = {
      selected: this.props.selected
    };
  }

  handleClick = (label) => {
    return () => this.setSelected(label);
  }

  setSelected = (selected) => {
    this.setState((state) => (state.selected === selected ? null : { ...state, selected: selected }));
  }

  renderChildren(children){
    const { selected } = this.state;

    return React.Children.map(children, (child) => {
      switch (child.type.displayName){
        case 'MBTablist':
          return this.renderTablist(child);
        case 'MBTabpanel':
          return React.cloneElement(child, { selected });
        default:
          return child;
      }
    });
  }

  renderTablist(child){
    const { selected } = this.state;

    return React.cloneElement(child, {
      children: React.Children.map(child.props.children, (tab) => {
        if (tab.type.displayName === 'MBTab'){
          return React.cloneElement(tab, {
            onTabClick: this.handleClick(tab.props.label),
            selected: selected
          });
        } else {
          return tab;
        }
      })
    });
  }

  render(){
    const { children } = this.props;

    return this.renderChildren(children);
  }
}

export { MBTab, MBTablist, MBTabpanel, MBTabs };
