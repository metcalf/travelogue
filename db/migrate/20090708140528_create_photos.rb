class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos do |t|
      # For FlexImage
      t.column :image_filename,   :string
      t.column :image_width,      :integer
      t.column :image_height,     :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :photos
  end
end
