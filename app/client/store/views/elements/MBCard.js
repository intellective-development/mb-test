// @flow
import * as React from 'react';
import bindClassNames from '../../../shared/utils/bind_classnames';
import styles from './MBCard.scss';

const cn = bindClassNames(styles);

type MBCardTitleProps = {
  children: string
}

const MBCardTitle = ({ children }: MBCardTitleProps) => (
  <div className={cn('elMBCardTitle')}>
    {children}
  </div>
);

type MBCardSectionProps = {
  children: React.Node,
  className?: string
}

const MBCardSection = ({ children, className }: MBCardSectionProps) => (
  <div className={cn('elMBCardSection', className)}>
    {children}
  </div>
);

const MBCardSpacer = () => (
  <div className={cn('elMBCardSpacer')} />
);

type MBCardProps = {
  children: React.Element<typeof MBCardSection>,
  className?: string
}

const MBCard = ({ children, className }: MBCardProps) => {
  return (
    <div className={cn('elMBCardContainer')}>
      <div className={cn('elMBCard', className)}>
        {children}
      </div>
    </div>
  );
};

MBCard.Title = MBCardTitle;
MBCard.Section = MBCardSection;
MBCard.Spacer = MBCardSpacer;
export default MBCard;
