import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getFormValues } from 'redux-form';
import { Cocktail } from '../../../../../cocktails/CocktailDetailPage';
import '../../../../../../assets/stylesheets/minibar/cocktails/index.scss';

const CocktailFormPreview = (props) => {
  return (
    <div style={{ width: 1000 }}>
      <Cocktail {...props} />
    </div>
  );
};

const CocktailFormPreviewSTP = (state) => ({
  cocktail: getFormValues('Cocktail')(state) || {}
});

export default withRouter(connect(CocktailFormPreviewSTP)(CocktailFormPreview));

