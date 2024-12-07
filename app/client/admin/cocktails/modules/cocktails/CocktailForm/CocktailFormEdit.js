import React from 'react';
import { Field, FieldArray } from 'redux-form';
import BrandsSelector from '../../../components/BrandsSelector';
import CocktailsSelector from '../../../components/CocktailsSelector';
import Input from '../../../components/Input';
import Chips from '../../../components/Chips';
import Image from '../../../components/Image';
import ToolsSelector from '../../../components/ToolsSelector';

const required = value => (value || typeof value === 'number' ? undefined : 'This field is required');

const CocktailFormEdit = ({ permalink }) => {
  return (
    <div>
      <fieldset>
        <legend>Title</legend>

        <Field name="name" validate={required} component={Input} label="Cocktail Name*" placeholder="Cocktail Name" />

        <Field name="brand" component={BrandsSelector} label="Cocktail Sponsor" placeholder="Cocktail Sponsor" />

        <Field name="related_cocktails" component={CocktailsSelector} label="Related cocktails" placeholder="Related cocktails" />

        <br />
        <Field name="tools" component={ToolsSelector} label="Tools" placeholder="Tools" />

        <br />
        <Field name="tags" component={Chips} label="Tags" placeholder="Cocktail tags" />

      </fieldset>

      <FieldArray name="images" component={CocktailImages} />

      <Field name="thumbnail" component={Image} label="Thumbnail" />

      <fieldset>
        <legend>Description*</legend>

        <Field name="description" validate={required} component="textarea" placeholder="Description" />

      </fieldset>

      <fieldset>
        <legend>Ingredients</legend>

        <Field name="serves" component={Input} label="Serves" placeholder="Serves" />

        <FieldArray name="ingredients" component={Ingredients} />

      </fieldset>

      <fieldset>
        <legend>Instructions</legend>

        <FieldArray name="instructions" component={Instructions} />

      </fieldset>

      {permalink && <fieldset>
        <legend>Deep link</legend>

        This can be used to link directly to this product from an external website or email.

        <input type="text" value={`${window.location.origin}/store/cocktails/${permalink}`} readOnly />

      </fieldset>}
    </div>
  );
};

export default CocktailFormEdit;

const renderImageField = (member, index, fields) => {
  return (
    <fieldset key={index}>
      <Field name={`${member}`} component={Image} />
      <div style={{ float: 'right' }}>
        <input type="hidden" value="false" name="product[images_attributes][0][_destroy]" id="product_images_attributes_0__destroy" />
        <a role="button" tabIndex={0} className="remove_child" onClick={fields.remove.bind(null, index)}>remove</a>
      </div>
    </fieldset>
  );
};

const CocktailImages = ({ fields, placeholder }) => (
  <fieldset>
    <legend>
      {placeholder || 'Images'} - <a role="button" tabIndex={0} className="add_child" onClick={fields.push.bind(null, undefined)}>New Image</a>
    </legend>

    <div id="product_images" className="span-16">
      {
        fields.map(renderImageField)
      }
    </div>
  </fieldset>
);

const Instruction = (member, index, fields) => {
  const stepTitle = `Step ${index + 1}`;
  return (
    <div key={index} className="instruction">
      <Field name={`${member}`} component={Input} label={stepTitle} />
      <div className="button-block">
        <button onClick={fields.move.bind(null, index, index - 1)} disabled={index <= 0}>&uarr;</button>
        <button onClick={fields.move.bind(null, index, index + 1)} disabled={index >= fields.length - 1}>&darr;</button>
      </div>
      <button onClick={fields.remove.bind(null, index)}>X</button>
    </div>
  );
};

const Instructions = ({ fields, meta: { error } }) => (
  <ul>
    {fields ? fields.map(Instruction) : null}
    <li>
      <button type="button" onClick={fields.push.bind(null, undefined)}>Add</button>
    </li>
    {error && <li className="error">{error}</li>}
  </ul>
);

const Product = (member, index, fields) => {
  return (
    <div key={index} className="ingredient">
      <div className="flex-row">
        <Field className="flex-item" name={`${member}.name`} component={Input} label="Ingredient name (displayed value)" />
        <Field className="flex-item" name={`${member}.qty`} component={Input} label="Quantity ( ½ ⅓ ⅔ ¼ ¾ ⅕ ⅖ ⅗ ⅘ ⅙ ⅚ ⅐ ⅛ ⅜ ⅝ ⅞ ⅑ ⅒ )" />
      </div>
      <div className="flex-row">
        <div className="flex-item" />
      </div>
      <div className="flex-row">
        <Field className="flex-item" name={`${member}.product`} component={Input} label="Product url" />
        <button onClick={fields.remove.bind(this, index)}>Remove</button>
      </div>
    </div>
  );
};

const Ingredients = ({ fields, meta: { error } }) => (
  <ul>
    {fields ? fields.map(Product) : null}
    <li>
      <button type="button" onClick={fields.push.bind(null, undefined)}>Add new ingredient</button>
    </li>
    {error && <li className="error">{error}</li>}
  </ul>
);
