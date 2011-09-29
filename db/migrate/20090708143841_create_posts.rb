class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.column :start,       :datetime, :null => false
      t.column :finish,         :datetime
      t.column :title,       :string, :null => false
      t.column :content,     :text

      t.column :place_string,     :string
      t.column :lat,              :float
      t.column :lng,              :float

      t.column :remote_ref,       :string
      t.column :remote_source_id, :string

      t.column :trip_id,     :integer, :null => false
      t.column :photo_id,    :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :posts
  end
end
