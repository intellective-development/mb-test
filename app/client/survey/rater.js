import _ from 'lodash';
import * as React from 'react';
import RaterStar from './rater_star';

class Rater extends React.Component {
  constructor(props){
    super(props);
    this.state = {
      hoverScore: this.props.score,
      total: this.props.total || 5
    };
  }

  onMouseOver = (value) => {
    this.setState({
      hoverScore: value
    });
  }

  onMouseOut = () => {
    this.setState({
      hoverScore: this.props.score
    });
  }

  updateRating = (newRating) => {
    this.props.ratingClicked(newRating);
  }

  render(){
    const stars = [];
    _.times(this.state.total, (index) => {
      stars.push(
        <RaterStar
          key={index + 1}
          updateRating={() => this.updateRating(index + 1)}
          hover={this.onMouseOver}
          exit={this.onMouseOut}
          value={index + 1}
          hoverScore={this.state.hoverScore} />
      );
    });

    return (
      <div className="small-6 small-offset-3 columns rating-group">
        {stars}
      </div>
    );
  }
}

export default Rater;
