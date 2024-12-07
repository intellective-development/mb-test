module Geo
  class GeometryBuilderService
    attr_reader :points, :factory, :type, :radius, :center_lat, :center_lng

    def initialize(params)
      hashed_params = if params.instance_of?(ActionController::Parameters)
                        params.to_unsafe_h.deep_symbolize_keys
                      else
                        params.deep_symbolize_keys
                      end

      @points = hashed_params[:points]
      @type = hashed_params[:type].to_sym

      if type == :circle
        # Radius should be provided in meters, no need to convert.
        @radius = Float(hashed_params[:radius])

        @center_lat = Float(hashed_params.dig(:center, :lat))
        @center_lng = Float(hashed_params.dig(:center, :lng))
      end
    end

    def build
      case type
      when :polygon then create_polygon
      when :circle then create_circle
      when :zipcode_polygon then create_zipcode_polygons
      end
    end

    private

    def factory
      @factory ||= RGeo::Cartesian.factory
    end

    def create_zipcode_polygons
      polygons = []
      points.each do |data|
        parsed_points = []
        data.each do |coords|
          parsed_points << build_point(coords[1], coords[0])
        end
        line_string = build_line_string(parsed_points)
        polygons << build_polygon(line_string)
      end
      polygons
    end

    def create_polygon
      line = points.map { |p| build_point(p[:lat], p[:lng]) }
      line << line.first # Close the loop
      line_string = build_line_string(line)
      build_polygon(line_string)
    end

    def create_circle
      line_string = build_line_string(build_circle_path)
      build_polygon(line_string)
    end

    # We need to do some translation of the projection in order to ensure
    # the circular polygon is consistant with the drawn geometry - doing this
    # using RGeo's .buffer function results in ovals so we need to break out
    # the math.
    #
    # https://s-media-cache-ak0.pinimg.com/originals/2a/3d/f9/2a3df9ee541ecacd9950ef48ec268a84.jpg
    CIRCLE_RESOLUTION = 32
    MERCATOR_RADIUS = 6_378_137.0
    DEGREES_TO_RADIANS = Math::PI / 180

    def build_circle_path
      point_multipliers ||= begin
        angle = 2 * Math::PI / CIRCLE_RESOLUTION
        Array.new(CIRCLE_RESOLUTION) do |i|
          radians = angle * i
          y = Math.sin(radians)
          x = Math.cos(radians)
          [y.abs < 0.01 ? 0.0 : y, x.abs < 0.01 ? 0.0 : x]
        end
      end

      lat = radius / (MERCATOR_RADIUS * DEGREES_TO_RADIANS)
      lng = radius / (MERCATOR_RADIUS * Math.cos(DEGREES_TO_RADIANS * center_lat) * DEGREES_TO_RADIANS)
      point_multipliers.map { |multiplier| build_point(center_lat + multiplier[0] * lat, center_lng + multiplier[1] * lng) }
    end

    def build_point(latitude, longitude)
      factory.point(latitude, longitude)
    end

    def build_line_string(point_array)
      factory.line_string(point_array)
    end

    def build_polygon(line_string)
      factory.polygon(line_string)
    end
  end
end
