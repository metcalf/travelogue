include Geokit::Geocoders
include Fleximage::Helper

class Post < ActiveRecord::Base
  CONTENT_PLACEHOLDER = "This post doesn't have any content yet!"

  belongs_to :trip
  belongs_to :photo, :dependent => :destroy

  has_many :locations, :dependent => :destroy

  validates_length_of :title, :in => 1..255, :unless => Proc.new { |post| post.photo }
  validates_presence_of :title, :unless => Proc.new { |post| post.photo }
  validates_presence_of :trip_id
  validates_presence_of :start
  validate :end_after_start, :geocode_location 

  def end_after_start
    errors.add_to_base("Event must finish after the start") unless finish == nil or finish > start
  end

  def geocode_location
    if(place_string)
      _locations = []
      place_string.split(";").each do |address|
        geo=Geokit::Geocoders::MultiGeocoder.geocode(address)
        errors.add(:address, "Could not Geocode address") if !geo.success
        _locations << {:lat => geo.lat, :lng => geo.lng} if geo.success
      end
      self.locations.delete_all
      self.locations = _locations.map {|params| Location.create!(params)}
    elsif(photo)
      closest = closest_post
      if(closest)
        self.locations = [Location.create!(:lat => closest.locations.first.lat, :lng => closest.locations.first.lng)]
      end
    end
  end

  def concurrent_posts(limit = 1)
    return Post.find(:all, :conditions => ["start < :time and finish > :time and trip_id = :trip_id and place_string IS NOT NULL and photo_id IS NULL", {:time => start, :trip_id => trip.id}], :limit => limit)
  end

  def earlier_posts(limit = 1)
    Post.find(:all, :conditions => ["finish < :time and trip_id = :trip_id and place_string IS NOT NULL and photo_id IS NULL", {:time => start, :trip_id => trip.id}], :order => 'finish DESC', :limit => limit)
  end

  def later_posts(limit = 1)
    Post.find(:all, :conditions => ["start  > :time and trip_id = :trip_id and place_string IS NOT NULL and photo_id IS NULL", {:time => start, :trip_id => trip.id}], :order => 'start  ASC ', :limit => limit)
  end

  def closest_posts(concurrent = 5, earlier = 5, later = 5)
    earlier_posts(earlier) + concurrent_posts(concurrent) + later_posts(later) 
  end

  def closest_post
    if(Post.exists?(["trip_id = ? and place_string IS NOT NULL and photo_id IS NULL", trip.id]))
      # Find an event occuring during this photo
      possibles = (concurrent_posts(2)+earlier_posts(2)+later_posts(2))
      # Find the event with the closest start or end time
      return possibles.min {|a,b| time_difference(a) <=> time_difference(b)}

    else
      return nil
    end

  end

  def time_difference(post)
    finish = self.finish
    finish ||= self.start
    
    ((self.start-post.start).abs+(self.start-post.finish).abs)
  end

  def closest_post_id
    closest_post.id
  end

  def point_time
    if(!finish)
      start
    else
      ((start-finish)/2).seconds.since(finish)
    end
  end

  def album
    Post.find(:all, :conditions => ["created_at = ? and photo_id IS NOT NULL", created_at])   
  end

  # For testing
  def lat  
    loc = self.locations.first
    loc.lat if loc
  end

  def lng
    loc = self.locations.first
    loc.lng if loc
  end

  def locations_eql?(other_locations)
    return false unless self.locations.length == other_locations.length

    self.locations.each do |location|
      found = false
      other_locations.each do |other_location|
        if(other_location.lat == location.lat && other_location.lng == location.lng)
          found = true
        end
      end
      return false unless found
    end

    return true
  end

end
