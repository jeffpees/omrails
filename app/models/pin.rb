require 'open-uri'
require 'timeout'

class Pin < ActiveRecord::Base

  belongs_to :user
  
  attr_accessor :image_url
  attr_accessible :description, :image, :image_url, :image_remote_url

  before_validation :download_remote_image, :if => lambda { |pin| pin.image_url.present? }

  has_attached_file :image, 
                    styles: { medium: "320x240>"}
                    #:storage => :s3, 
                    #:s3_credentials => S3_CREDENTIALS

  validates :description, presence: true
  validates :user_id, presence: true
  validates_attachment :image, presence: true,
  														 content_type: { content_type: ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/img'] },
  														 size: { less_than: 5.megabytes } 

  private
  
  def image_url_provided?
    !self.image_url.blank?
  end

  def download_remote_image
    return if self.image.present?
    	begin
	      Timeout::timeout(2) do
	        io = open URI.parse(image_url)
	        def io.original_filename
	        	base_uri.path.split('/').last.scan(/([\w\.]*\.(?:png|jpe?g|gif|bmp|JPG|JPEG|BMP|GIF|PNG))/).flatten.first
	      	end
	      self.image = io.original_filename.blank? ? nil : io
  end
    rescue Exception => e
      Rails.logger.error "Failed to download image from \"#{image_url}\": #{e.message}"
    end
  end
end
