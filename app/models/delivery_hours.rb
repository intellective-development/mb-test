class DeliveryHours
  include Comparable
  include ActiveModel::Conversion
  include ActiveModel::Validations
  extend ActiveModel::Naming

  attr_accessor :starts_at, :ends_at, :wday, :id

  validates :starts_at, presence: true,
                        format: { with: CustomValidators::Time.clock_validator }
  validates :ends_at, presence: true,
                      format: { with: CustomValidators::Time.clock_validator },
                      delivery_hours: true
  validates :wday, presence: true

  delegate :days_of_week, to: :class

  #------------------------------------
  # Class methods
  #------------------------------------
  def self.days_of_week
    %i[sun mon tue wed thu fri sat]
  end

  #------------------------------------
  # instance methods
  #------------------------------------
  # id=wday is necessary for stores that have multiple delivery hours
  # for a shipping method
  def initialize(wday, (starts_at, ends_at), id = wday)
    @wday      = wday.is_a?(Symbol) ? wday : days_of_week[wday.to_i]
    @starts_at = starts_at
    @ends_at   = ends_at
    @id        = id
  end

  def persisted?
    true
  end

  # def id
  #   days_of_week.index(wday)
  # end

  def <=>(other)
    if comparable_time(starts_at) < comparable_time(other.starts_at) ||
       comparable_time(ends_at) < comparable_time(other.ends_at)
      -1
    elsif comparable_time(starts_at) > comparable_time(other.starts_at) ||
          comparable_time(ends_at) > comparable_time(other.ends_at)
      1
    else
      0
    end
  end

  private

  def comparable_time(time)
    time.nil? ? Time.new(0).in_time_zone : Time.zone.parse(time)
  end
end
