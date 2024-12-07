// @flow

import React from 'react';
import { MBDynamicIcon } from '../../../elements';
import { MBTab, MBTablist, MBTabs } from '../../../elements/MBTabs';

type ContainerListProps = {
  containers: Array<String>,
  onSelect: ?Func,
  selected: string
}
const ContainerList = ({ containers, onSelect, selected }: ContainerListProps) => {
  if (containers.length <= 1){
    return null;
  }

  return (
    <MBTabs selected={selected}>
      <MBTablist className="variant_container">
        {containers.map(container => (
          <MBTab
            key={container}
            label={container}
            onClick={() => onSelect(container)}
            selected={selected}>
            <MBDynamicIcon
              color="transparent"
              height={25}
              name={container.toLowerCase()}
              width={25} />
          </MBTab>
        ))}
      </MBTablist>
    </MBTabs>
  );
};

export default ContainerList;
