# == Schema Information
#
# Table name: zipcode_geoms
#
#  id         :integer          not null, primary key
#  zcta5ce10  :string
#  geoid10    :string
#  classfp10  :string
#  mtfcc10    :string
#  funcstat10 :string
#  aland10    :float
#  awater10   :float
#  intptlat10 :string
#  intptlon10 :string
#  geom       :geometry         multipolygon, 4326
#  zcta5ce20  :string
#  geoid20    :string
#  classfp20  :string
#  mtfcc20    :string
#  funcstat20 :string
#  aland20    :float
#  awater20   :float
#  intptlat20 :string
#  intptlon20 :string
#
# Indexes
#
#  index_zipcode_geoms_on_geom       (geom) USING gist
#  index_zipcode_geoms_on_zcta5ce10  (zcta5ce10)
#  index_zipcode_geoms_on_zcta5ce20  (zcta5ce20)
#  zipcode_geoms_geom_idx            (geom) USING gist
#  zipcode_geoms_geom_idx1           (geom) USING gist
#

class ZipcodeGeom < ActiveRecord::Base
end
