// @flow

import * as React from 'react';

import bindClassNames from '../../../shared/utils/bind_classnames';
import styles from './MBProductVideo.scss';

const cn = bindClassNames(styles);

type VideoContent = {
  primary_background_color: string,
  secondary_background_color: string,
  video: {
    mp4: string,
    poster: string
  }
}

type ProductVideoProps = {
  id: string,
  content: VideoContent | false,
  click_tracking_id: string,
  impression_tracking_id: string
}

const ProductVideo = ({ content }: ProductVideoProps) => {
  if (!content) return null;

  const video_style = {
    backgroundColor: content.secondary_background_color
  };

  return (
    <div className={cn('elMBProductVideo')}>
      <div className={cn('elMBProductVideo__Video', 'row')}>
        <video
          className="video-js vjs-default-skin vjs-big-play-centered"
          id="enhanced-content"
          width="auto"
          height="auto"
          controls
          poster={content.video.poster}
          style={video_style}>
          <source src={content.video.mp4} type="video/mp4" />
        </video>
      </div>
    </div>
  );
};

export default ProductVideo;
