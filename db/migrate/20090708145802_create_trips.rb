class CreateTrips < ActiveRecord::Migration
  def self.up
    create_table :trips do |t|
      t.column :title,            :string, :null => false, :limit => 60
      t.column :description,      :string, :default => ""

      t.column :user_id,          :integer, :null => false
      t.column :post_id,          :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :trips
  end
end
