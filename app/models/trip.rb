require 'date'
require 'net/http'

class Trip < ActiveRecord::Base
  acts_as_mappable

  attr_accessor :ics_url

  include Icalendar 

  belongs_to :user
  
  belongs_to :top_right_location, :class_name => 'Location', :dependent => :destroy
  belongs_to :bottom_left_location, :class_name => 'Location', :dependent => :destroy

  has_many :posts, :dependent => :destroy
   
  belongs_to :post, :dependent => :destroy # This is where the image for the trip resides

  validates_length_of :title, :in => 1..60
  validates_length_of :description, :maximum => 255
  validates_presence_of :user_id

  def start
    post = posts.find(:first, :order => "start ASC")
    post ? post.start : nil
  end

  def finish  
    post = posts.find(:first, :order => "finish DESC")
    post ? post.finish : nil
  end

  def summary
    ""
  end

  def self.bounds_for(locations)
    if(locations.length == 1)
      tr_location = Location.new(:lat => locations.first.lat, :lng => locations.first.lng)
      bl_location = nil
    elsif(locations.length > 1)
      lats = locations.map {|loc| loc.lat }
      lngs = locations.map {|loc| loc.lng }

      tr_location = Location.new(:lat =>lats.max, :lng =>lngs.max)
      bl_location = Location.new(:lat =>lats.min, :lng =>lngs.min)
    end
    
    [tr_location, bl_location]
  end

  def reset_bounds
    locations = posts.map {|post| post.locations}.flatten

    self.top_right_location, self.bottom_left_location = Trip.bounds_for(locations)
    self.save
  end

  def bounds
    [top_right_location, bottom_left_location].compact
  end

  def bounds_for_google
    case bounds.length
      when 0
        nil
      when 1
        {:lon => bounds.first.lon, :lat => bounds.first.lat}
      else
        [
         {:lon => self.top_right_location.lng, :lat => self.top_right_location.lat},
         {:lon => self.top_right_location.lng, :lat => self.bottom_left_location.lat},
         {:lon => self.bottom_left_location.lng, :lat => self.bottom_left_location.lat},
         {:lon => self.bottom_left_location.lng, :lat => self.top_right_location.lat},
         {:lon => self.top_right_location.lng, :lat => self.top_right_location.lat}
        ]
    end

  end

  def import_posts_url(cal_file_url, options = {})
    cal_file = Net::HTTP.get URI.parse(cal_file_url)
    options[:remote_ref] ||= cal_file_url
    import_posts(cal_file, options)
  end

  def import_posts(cal_file, options = {})
    remote_ref = options[:remote_ref] if options.has_key?(:remote_ref)  
    start = options[:start] if options.has_key?(:start)
    finish = options[:finish] if options.has_key?(:finish)

    if(start and start.kind_of?(String))
      start = DateTime.parse(start)
    end
    if(finish and finish.kind_of?(String))
      finish = DateTime.parse(finish)
    end
    
    cal_file.gsub!("SUMMARY:Busy\r\n", '')
    cal = Icalendar.parse(cal_file).first

    posts_data = cal.events.map do |event|
      if((!start or event.dtstart > start ) and (!finish or event.dtend < finish))
        post_data = {
             :title => event.summary.strip,
             :content => event.description,
             :start => event.dtstart,
             :finish => event.dtend,
             :remote_source_id => event.uid.strip,
             :remote_ref => remote_ref,
             :trip_id => self.id
                }

        post_data[:place_string] = event.location if event.location && !event.location.empty?

        post_data
      else
        nil
      end 
    end

    posts_data.compact!
    failed = []
    posts_data.each do |post_data|
      Post.destroy_all(:remote_ref => post_data[:remote_ref],
                       :remote_source_id => post_data[:remote_source_id],
                       :trip_id => self.id)

      post = Post.new(post_data)
      if(!post.save)
        failed << post
      end
    end 

    failed
  end
end
