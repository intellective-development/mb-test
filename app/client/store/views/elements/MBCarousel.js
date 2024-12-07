// @flow

import * as React from 'react';
import _ from 'lodash';
import Slider from 'react-slick';
import { trackPlacementImpression } from '../compounds/GenericContentModule/placement_tracking';
import WithPromotionTracking from '../compounds/WithPromotionTracking';
import MBLink from './MBLink';
import * as MBText from './MBText';
import './MBCarousel.scss';

type ImageContent = {
  image_url: string,
  name: string,
  image_width: number,
  image_height: number,
  secondary_image_url: string,
  action_url: string,
  click_tracking_url: string,
  impression_tracking_url: string
};

type CarouselContentProps = {
  content: ImageContent[]
};

const Carousel = (props: CarouselContentProps) => {
  if (_.isEmpty(props.content)){
    return (<CarouselLoadingContent />);
  }

  if (!props.first_only && props.content.length > 1){
    return (
      <Slider dots {...props}>
        {props.content.map(content => (
          <CarouselContent
            banner={content}
            key={content.internal_name} />
        ))}
      </Slider>
    );
  }

  return <CarouselContent banner={props.content[0]} />;
};

const isMissing = (image_url: string) => image_url.indexOf('missing.png') > -1;

class CarouselContent extends React.Component<*> {
  componentDidMount(){
    trackPlacementImpression(this.props.banner);
  }

  render(){
    const { banner } = this.props;

    if (isMissing(banner.image_url)){
      return <MBText.H2 className="el-carousel__missing">{banner.name}</MBText.H2>;
    } else {
      return <CarouselContentImage image={banner} />;
    }
  }
}

const CarouselContentImage = ({
  image: { action_url, image_url, secondary_image_url, image_height, image_width, name }
}: {
  image: ImageContent
}) => (
  <WithPromotionTracking render={({ trackPromotion }) => (
    <MBLink.View
      href={action_url}
      className="el-carousel"
      title={name}
      beforeNavigate={() => trackPromotion(name, 'carousel-content-module')}
      disabled={!action_url}>
      <picture>
        <source
          media="(max-width: 767px)"
          srcSet={secondary_image_url} />
        <source
          media="(min-width: 768px)"
          srcSet={image_url} />
        <img
          className="el-carousel__image"
          src={image_url}
          width={image_width}
          height={image_height}
          alt={name} />
      </picture>
    </MBLink.View>
  )} />
);

const CarouselLoadingContent = () => (
  <div className="store-carousel__placeholder" />
);

export default Carousel;
