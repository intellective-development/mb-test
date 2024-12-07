import { compact } from 'lodash';
import React, { useEffect } from 'react';
import { connect } from 'react-redux';
import { GetCocktailRoutine, selectCocktailById } from '@minibar/store-business/src/cocktails/cocktails.dux';
import BrowseBreadcrumbs from '../store/views/compounds/BrowseBreadcrumbs';
import Ingredient from './Ingredient';
import Tool from './Tool';
import { renderCocktail } from './CocktailListPage';

class CocktailDetailPage extends React.Component {
  componentDidMount(){
    const { match, getCocktail } = this.props;
    getCocktail({ id: match.params.id });
  }

  componentDidUpdate(oldProps){
    const { match, getCocktail } = this.props;
    if (match.params !== oldProps.match.params){
      getCocktail({ id: match.params.id });
    }
  }

  render(){
    const { name, permalink } = this.props.cocktail || {};
    return [
      <div key="breadcrumb" className="el-mblayouts-sg _pad_sides scPDP_BreadcrumbContainer">
        <BrowseBreadcrumbs breadcrumbs={[{
          description: 'home',
          destination: '/'
        }, {
          description: 'cocktails',
          destination: '/store/cocktails'
        }, {
          description: name,
          destination: `/store/cocktails/${permalink}`
        }]} />
      </div>,
      <Cocktail key="cocktail" {...this.props} />
    ];
  }
}

const CocktailDetailPageSTP = (state, props) => {
  return ({
    cocktail: selectCocktailById(state)(props.match.params.id)
  });
};

const CocktailDetailPageDTP = ({
  getCocktail: GetCocktailRoutine.trigger
});

export default connect(CocktailDetailPageSTP, CocktailDetailPageDTP)(CocktailDetailPage);

const CocktailFeaturedImage = (props) => {
  // eslint-disable-next-line quotes
  const url = `${props.src}`.replace(new RegExp("'", 'g'), `\\'`);
  return (
    <div
      className="cocktail-image-container"
      style={{ backgroundImage: `url('${url}')` }} />
  );
};

function renderTool(tool){
  return <Tool key={tool.id} {...tool} />;
}

function renderIngredient(ingredient){
  return <Ingredient key={ingredient.name} {...ingredient} />;
}

const onFacebookShare = ({ permalink, name, image }, e) => {
  e.preventDefault();
  window.FB.ui({
    method: 'share_open_graph',
    action_type: 'og.likes',
    action_properties: JSON.stringify({
      object: {
        'og:url': `https://${window.location.host}/store/cocktails/${permalink}`,
        'og:title': `${name}`,
        'og:description': `Check out the ${name} cocktail on @MinibarDelivery`,
        'og:image': image
      }
    })
  });
};

class FacebookProvider extends React.Component {
  componentDidMount(){
    window.fbAsyncInit = function(){
      window.FB.init({
        appId: window.fbAppId,
        autoLogAppEvents: true,
        xfbml: true,
        version: 'v3.1'
      });
    };

    (function(d, s, id){
      const fjs = d.getElementsByTagName(s)[0];
      if (d.getElementById(id)){ return; }
      const js = d.createElement(s);
      js.id = id;
      js.src = 'https://connect.facebook.net/en_US/sdk.js';
      fjs.parentNode.insertBefore(js, fjs);
    }(document, 'script', 'facebook-jssdk'));
  }

  render(){
    return this.props.children;
  }
}

export function Cocktail(props){
  const { cocktail = {} } = props || {};
  const { images, brand, serves, description, name, related_cocktails = [], instructions = [], ingredients = [], tools = [] } = cocktail || {};
  let image;
  if (images && images[0] && images[0].image_url){
    image = images[0].image_url;
  }

  useEffect(() => {
    // Intentionally skipping SEO optimization when previewing cocktails in /admin
    if (window.location.pathname.startsWith('/admin')) return;
    document.querySelector('meta[name="description"]')
      .setAttribute('content', description);
    document.title = compact([name, 'Cocktail Recipe - Minibar Delivery'])
      .join(' ');
  }, [description, name]);

  return (
    <FacebookProvider>
      <div className="cocktail">
        <div className="el-mblayouts-sg _pad_sides">
          <div className="flex-row cocktail-title">
            <div className="flex">
              <CocktailFeaturedImage src={image} />
            </div>
            <div className="flex">
              <h1>{cocktail.name}</h1>
              {brand ? <div className="recipe">Recipe by <a href={`/store/brand/${brand.permalink}`}>{brand.name}</a></div> : null}

              <ul className="inline-list icon--social__list">
                <li className="icon--social__list--list_item footer__list-item">
                  <a
                    target="_blank"
                    title="Facebook share link"
                    rel="noopener noreferrer"
                    onClick={onFacebookShare.bind(this, { ...cocktail, image })}
                    href="#share">
                    <img className="social-icon" srcSet="https://cdn.minibardelivery.com/assets/social_icons/facebook@2x.png 2x, https://cdn.minibardelivery.com/assets/social_icons/facebook@3x.png 3x" src="https://cdn.minibardelivery.com/assets/social_icons/facebook@1x.png" alt="Facebook@1x" />
                    <img className="social-icon-hover" srcSet="https://cdn.minibardelivery.com/assets/social_icons/facebook_hover@2x.png 2x, https://cdn.minibardelivery.com/assets/social_icons/facebook_hover@3x.png 3x" src="https://cdn.minibardelivery.com/assets/social_icons/facebook_hover@1x.png" alt="Facebook hover@1x" />
                  </a>
                </li>
                <li className="icon--social__list--list_item footer__list-item">
                  <a
                    target="_blank"
                    rel="noopener noreferrer"
                    title="Twitter share link"
                    href={`https://twitter.com/home?status=Check out the ${cocktail.name} cocktail on @MinibarDelivery https://minibardelivery.com/store/cocktail/${cocktail.permalink}`}>
                    <img className="social-icon" srcSet="https://cdn.minibardelivery.com/assets/social_icons/twitter@2x.png 2x, https://cdn.minibardelivery.com/assets/social_icons/twitter@3x.png 3x" src="https://cdn.minibardelivery.com/assets/social_icons/twitter@1x.png" alt="Twitter@1x" />
                    <img className="social-icon-hover" srcSet="https://cdn.minibardelivery.com/assets/social_icons/twitter_hover@2x.png 2x, https://cdn.minibardelivery.com/assets/social_icons/twitter_hover@3x.png 3x" src="https://cdn.minibardelivery.com/assets/social_icons/twitter_hover@1x.png" alt="Twitter hover@1x" />
                  </a>
                </li>
              </ul>

              <div className="description">{description}</div>
            </div>
          </div>

          <div className="flex-row cocktail-parts">
            <div className="flex flex-row ingredients">
              <div className="block">
                <h5 className="block-header">INGREDIENTS</h5>
                {serves ? <div className="serves">Serves: {serves}</div> : null}
                <ul className="block-list ingredients-list">
                  {ingredients.map(renderIngredient)}
                </ul>
              </div>
            </div>
            <div className="flex flex-row instructions">
              <div className="block">
                <h5 className="block-header">INSTRUCTIONS</h5>
                <ol className="block-list instructions-list">
                  {instructions.map((instruction) => <li key={instruction}><span className="instruction">{instruction}</span></li>)}
                </ol>
              </div>
            </div>
            <div className="flex flex-row tools">
              <div className="block">
                <h5 className="block-header">TOOLS AND GLASSWARE</h5>
                <ul className="block-list tools-list">
                  {tools.map(renderTool)}
                </ul>
              </div>
            </div>
          </div>
        </div>
        { related_cocktails && related_cocktails.length ?
          <div className="el-mblayouts-sg _pad_sides">
            <h2 className="heading-row heading-row--has-subheader"> Related cocktails</h2>
            <div className="related-cocktails">
              {related_cocktails.map(renderCocktail)}
            </div>
          </div> : null }
      </div>
    </FacebookProvider>
  );
}
