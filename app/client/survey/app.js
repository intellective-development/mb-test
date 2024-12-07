import * as React from 'react';
import OrderSurveyFormFields from './order_survey_form_fields';
import OrderSurveyThankYou from './order_survey_thank_you';
import OrderSurveyInvalid from './order_survey_invalid';

const PENDING_STATE = 'pending';
const STARTED_STATE = 'started';
const COMPLETED_STATE = 'completed';

class App extends React.Component {
  constructor(props){
    super(props);
    this.state = {
      state: props.survey.state,
      score: props.survey.score || 0,
      selected_reasons: []
    };
  }

  submitForm = (score) => {
    this.setState({
      state: COMPLETED_STATE,
      score: score
    });
  }

  render(){
    switch (this.state.state){
      case PENDING_STATE:
        return <OrderSurveyFormFields survey={this.props.survey} submitForm={this.submitForm} />;
      case STARTED_STATE:
        return <OrderSurveyFormFields survey={this.props.survey} submitForm={this.submitForm} />;
      case COMPLETED_STATE:
        return <OrderSurveyThankYou referralReward={10} referralCode={this.props.referralCode} score={this.state.score} />;
      default:
        return <OrderSurveyInvalid />;
    }
  }
}

export default App;
