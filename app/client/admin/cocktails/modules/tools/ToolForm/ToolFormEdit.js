import React from 'react';
import { Field } from 'redux-form';
import Input from '../../../components/Input';
import Image from '../../../components/Image';

const ToolFormEdit = () => {
  return (
    <div>
      <fieldset>
        <legend>Title</legend>

        <Field name="name" component={Input} label="Tool Name" placeholder="Tool Name" />

        <Field name="description" component="textarea" placeholder="Description" />

        <fieldset>
          <label htmlFor="icon">Tool Icon:</label>
          <Field name="icon" component={Image} noLink label="icon" placeholder="icon" />
        </fieldset>
      </fieldset>
    </div>
  );
};

export default ToolFormEdit;
