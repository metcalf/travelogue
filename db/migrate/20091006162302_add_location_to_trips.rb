class AddLocationToTrips < ActiveRecord::Migration
  def self.up
    add_column :trips, :lat,    :float
    add_column :trips, :lng,    :float
    add_column :trips, :radius, :float
  end

  def self.down
    remove_column :trips, :lat
    remove_column :trips, :lng
    remove_column :trips, :radius
  end
end
