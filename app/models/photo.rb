class Photo < ActiveRecord::Base
  acts_as_fleximage :image_directory => 'public/images/uploaded_photos', :validates_image_size => "5x5"
end
