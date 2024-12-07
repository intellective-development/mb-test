import * as React from 'react';
import classNames from 'classnames';
import PropTypes from 'prop-types';

const ReasonSelector = ({ hidden, reasons, reasonClicked, selectedReasons }) => {
  // Force hidden class into reason-selector if score is 5
  const className = `small-12 columns react-reasons-section ${hidden}`;

  return (
    <div className={className}>
      <div className="large-12 header">What went wrong?</div>
      <div className={'react-reasons'}>
        {reasons.map((reason) => (
          <div
            tabIndex={0}
            key={reason.name}
            role="button"
            onClick={() => reasonClicked(reason)}
            className={classNames('reason', {
              selected: (selectedReasons.indexOf(reason) >= 0)
            })}>
            {reason.name}
          </div>
        ))}
      </div>
    </div>
  );
};

ReasonSelector.propTypes = {
  hidden: PropTypes.string,
  reasons: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string
  })),
  reasonClicked: PropTypes.func,
  selectedReasons: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string
  }))
};

export default ReasonSelector;
