# == Schema Information
#
# Table name: logos
#
#  id                 :integer          not null, primary key
#  image_file_name    :string(255)
#  image_content_type :string(255)
#  image_file_size    :integer
#  image_updated_at   :datetime
#  user_id            :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_logos_on_user_id  (user_id)
#

class Logo < ActiveRecord::Base
  has_paper_trail

  belongs_to :user
  has_many :supplier_logos, dependent: :destroy
  has_many :suppliers, through: :supplier_logos

  has_attached_file :image, BASIC_PAPERCLIP_OPTIONS.merge(
    styles: { original:     ['280x280>', :jpg] },
    processors: %i[trimmer padder],
    default_url: '/images/:style/missing.png',
    default_style: :small,
    keep_old_files: true,
    path: 'logo/:id/:style.:extension',
    hash_secret: Settings.paperclip.hash_secret
  )

  validates_attachment_content_type :image, content_type: %r{\Aimage/.*\Z}
  # validates :image, presence: true

  #-----------------------------------
  # Class methods
  #-----------------------------------

  def self.admin_grid(params = {})
    if params[:name].present?
      Logo.joins(:supplier_logos).joins(:suppliers).where('lower(suppliers.name) LIKE ?', "%#{params[:name].downcase}%").uniq
    else
      Logo.all
    end
  end
end
