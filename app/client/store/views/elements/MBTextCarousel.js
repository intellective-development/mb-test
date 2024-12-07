// @flow

import * as React from 'react';
import { trackPlacementClick, trackPlacementImpression } from '../compounds/GenericContentModule/placement_tracking';
import MBLink from './MBLink';
import * as MBText from './MBText';

type TextContent = {
  background_color: ?string,
  action_url: ?string,
  text_content: string,
  click_tracking_url: string,
  impression_tracking_url: string
};

type TextCarouselContentProps = {
  content: TextContent[]
}

const TextCarousel = (props: TextCarouselContentProps) => {
  if (props.content.length > 1){
    console.warn('handling for multiple content not yet implemented');
  }

  if (!props.content.length){
    return (<TextCarouselLoadingContent />);
  }

  return <TextCarouselContent banner={props.content[0]} />;
};

class TextCarouselContent extends React.Component<*> {
  componentDidMount(){
    trackPlacementImpression(this.props.banner);
  }

  render(){
    const { banner } = this.props;

    return (
      <MBLink.View
        className="el-carousel--text"
        style={{backgroundColor: banner.background_color}}
        href={banner.action_url}
        disabled={!banner.action_url}
        beforeNavigate={() => trackPlacementClick(banner)} >
        <MBText.H2 className="el-carousel--text-content">{banner.text_content}</MBText.H2>
      </MBLink.View>
    );
  }
}

const TextCarouselLoadingContent = () => (
  <div className="store-carousel__placeholder" />
);

export default TextCarousel;
