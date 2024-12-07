import React, { Component } from 'react';

class Image extends Component {
  onLinkChange({ target: { value }}){
    this.props.input.onChange({
      photo_from_link: value
    });
  }

  onFileChange({ target: { files = [] }}){
    this.props.input.onChange(files[0]);
  }

  render(){
    const { input, id, name, label, noLink = false } = this.props;
    const { value } = input || {};
    const { image_url } = value || {};

    if (image_url){
      return [
        <img key="img" src={image_url} alt="preview" />,
        <button key="button" onClick={this.props.input.onChange.bind(this, {})}>x</button>
      ];
    }

    const link_name = `${(name || input.name)}_link`;
    const link_id = `${id}_link` || link_name;
    const file_name = `${(name || input.name)}_file`;
    const file_id = `${id}_file` || file_name;

    return (
      <div>

        <label htmlFor={file_id}>{ label || (
          <div>
            Photo (Image spec:
            <strong> 685 x 350 or larger with the same aspect ratio </strong>
            (The image will be aspect filling the box depending on screen size).
          </div>
        )}</label>
        <p>
          <input
            type="file"
            onChange={this.onFileChange.bind(this)}
            onBlur={this.onFileChange.bind(this)}
            name={file_name}
            id={file_id} />
        </p>

        {
          noLink ? null : [
            <label key="label" htmlFor={link_id}>Link to image</label>,
            <input
              key="input"
              className="js-product-image"
              type="text"
              onChange={this.onLinkChange.bind(this)}
              name={link_name}
              id={link_id} />
          ]
        }
      </div>
    );
  }
}

export default Image;
