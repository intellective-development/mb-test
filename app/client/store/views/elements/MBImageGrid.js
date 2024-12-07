// @flow

import * as React from 'react';
import cn from 'classnames';
import type { ImageType } from '../../business/content_module';
import { MBLayout } from '../elements';
import MBLink from './MBLink';
import MBHeader from './MBHeader';

export type ImageGridProps = {
  title: string,
  action_url: string,
  content: ImageType[],
}

type GridProps = {
  tiles: ImageType[]
}

type TileProps = {
  tile: ImageType
}

const ImageGrid = ({ content, title }: ImageGridProps) => {
  return (
    <MBLayout.StandardGrid cols={1} className="el-image-grid">
      <MBHeader title={title} />
      <Grid tiles={content} />
    </MBLayout.StandardGrid>
  );
};

const Grid = ({ tiles }: GridProps) => (
  <div className="el-image-grid__container">
    {tiles.map((tile) => (<Tile key={tile.internal_name} tile={tile} />))}
  </div>
);

const Tile = ({ tile }: TileProps) => (
  <MBLink.View
    key={tile.internal_name}
    className={cn('el-image-grid__tile')}
    href={tile.action_url}
    disabled={!tile.action_url}>
    <img
      alt={tile.internal_name}
      className="el-image-grid__image"
      src={tile.image_url} />
  </MBLink.View>
);

export default ImageGrid;
