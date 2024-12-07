import 'whatwg-fetch';
import * as React from 'react';
import Rater from './rater';
import ReasonSelector from './reason_selector';
import sendForm from './send_survey_form_data';

class OrderSurveyFormFields extends React.Component {
  constructor(props){
    super(props);
    const initial_survey = this.props.survey;
    this.state = {
      state: initial_survey.state,
      score: initial_survey.score || 0,
      selected_reasons: [],
      comment: initial_survey.comment || ''
    };
  }

  getReasonSelectorClassname = () => (
    (this.state.score > 0 && this.state.score < 5) ? '' : 'hidden'
  );

  ratingClicked = (value) => {
    if (value === 5) this.setState({ selected_reasons: [] });
    this.setState({
      score: value
    });
  }

  reasonClicked = (reason) => {
    const { selected_reasons } = this.state;
    let next_reasons;
    if (selected_reasons.indexOf(reason) >= 0){
      next_reasons = selected_reasons.filter((value) => value !== reason);
    } else {
      next_reasons = [...selected_reasons, reason];
    }
    this.setState({
      selected_reasons: next_reasons
    });
  }

  commentChange = (e) => {
    this.setState({
      comment: e.target.value
    });
  }

  defineFormData = () => (
    {
      score: this.state.score,
      comment: this.state.comment,
      selected_reasons: this.state.selected_reasons
    }
  );

  submit = (e) => {
    e.preventDefault();
    const data = this.defineFormData();
    const { survey } = this.props;

    sendForm(survey, data).then(() => {
      this.props.submitForm(data.score);
    });
  }

  render(){
    return (
      <div className="checkout-frame no-bottom-margin">
        <div className="modal-header mega-header">
          <h3>Rate Your Minibar Delivery</h3>
        </div>
        <div className="checkout-panel mega-body rating">
          <form className="row" onSubmit={this.submit}>
            <Rater
              ratingClicked={this.ratingClicked}
              score={this.state.score} />
            <ReasonSelector
              reasons={window.reasons}
              hidden={this.getReasonSelectorClassname()}
              reasonClicked={this.reasonClicked}
              selectedReasons={this.state.selected_reasons} />
            <textarea onChange={this.commentChange} value={this.state.comment} placeholder="Any comments?" />
            <button className="button expand send" type="submit">Send Feedback</button>
          </form>
        </div>
      </div>
    );
  }
}

export default OrderSurveyFormFields;
