// @flow

import * as React from 'react';
import { Link } from 'react-router-dom';

//320x240 image base64
const placeholder = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAUAAAADwCAQAAADbJHXgAAABvklEQVR42u3SAQkAAAzDsM+/6csYjERCaQ6KIgEGxIBgQAwIBsSAYEAMCAbEgGBADAgGxIBgQAwIBsSAYEAMCAbEgGBADAgGxIBgQAwIBsSAYEAMiAHBgBgQDIgBwYAYEAyIAcGAGBAMiAHBgBgQDIgBwYAYEAyIAcGAGBAMiAHBgBgQDIgBwYAYEAyIATEgGBADggExIBgQA4IBMSAYEAOCATEgGBADggExIBgQA4IBMSAYEAOCATEgGBADggExIBgQA2JAMCAGBANiQDAgBgQDYkAwIAYEA2JAMCAGBANiQDAgBgQDYkAwIAYEA2JAMCAGBANiQDAgBgQDYkAMCAbEgGBADAgGxIBgQAwIBsSAYEAMCAbEgGBADAgGxIBgQAwIBsSAYEAMCAbEgGBADAgGxIBgQAyIAcGAGBAMiAHBgBgQDIgBwYAYEAyIAcGAGBAMiAHBgBgQDIgBwYAYEAyIAcGAGBAMiAHBgBgQA4IBMSAYEAOCATEgGBADggExIBgQA4IBMSAYEAOCATEgGBADggExIBgQA4IBMSAYEAOCATEgGBADYkAwIAYEA2JAMCAGBANiQDAgBgQDsuQBRpsA8U1JCw8AAAAASUVORK5CYII=';

const CocktailTile = ({ name, permalink, images, thumbnail }) => {
  let imageUrl;
  if (thumbnail && thumbnail.image_url){
    imageUrl = thumbnail.image_url;
  } else if (images && images[0] && images[0].image_url){
    imageUrl = images[0].image_url;
  }
  return (
    <Link to={`/store/cocktails/${permalink}`} className="cocktails-list-item">
      <div
        style={{ backgroundImage: `url(${imageUrl}` }}
        className="cocktails-list-item-image">
        <img
          src={placeholder}
          alt="ratio maintainer" />
      </div>
      <h5>{name}</h5>
    </Link>
  );
};

export default CocktailTile;
