include Geokit::Geocoders

class LocationToSeparateTable < ActiveRecord::Migration
  def self.up
    create_table "locations" do |t|
      t.column :lat, :float, :null => false
      t.column :lng, :float, :null => false

      t.column :post_id, :integer
    end

    add_index :locations, [:lat, :lng]

    Post.all.each do |post|
      if(post.place_string && !post.place_string.empty?)
        post.place_string.split(";").each do |address|
          geo = Geokit::Geocoders::GoogleGeocoder.geocode(address)
          if(geo.success)
            Location.create(:post_id => post.id, :lat=> geo.lat, :lng => geo.lng)
          else
            str = "Could not geocode #{address} for post #{post.id.to_s}\n"
            print str
            put str
          end
        end
      end 
    end

    remove_column :trips, :lat
    remove_column :trips, :lng
    remove_column :trips, :radius
    
    remove_column :posts, :lat
    remove_column :posts, :lng

    add_column :trips, :top_right_location_id, :integer
    add_column :trips, :bottom_left_location_id, :integer  
   
  end

  def self.down
    drop_table "locations"

    remove_column :trips, :top_right_location_id
    remove_column :trips, :bottom_left_location_id    
  end
end
