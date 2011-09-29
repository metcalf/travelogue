require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'geokit'

describe Trip do
  before(:each) do
    @valid_attributes = {
      :title => "Super Duper Trip",
      :user  => m_user  
    }
  end

  it "should create a new instance given valid attributes" do
    Trip.create!(@valid_attributes)
  end

  describe "basic attributes" do
    before :each do
      @trip = Trip.new(@valid_attributes)
    end

    after :each do
      @trip.save!
    end

    it "should accept a description" do
      @trip.description = "Yah, it was fun"
    end

    it "should associate with posts" do
      @trip.posts << m_post
    end

    it "should accept a primary post" do
      @trip.post = m_post
    end
  end

  describe "summary methods" do
    before :each do
      @trip = Trip.create(@valid_attributes)
      @finish = 1.days.ago
      @start  = 6.days.ago
      m_post(:finish => @finish, :start => 5.days.ago, :trip => @trip, :place_string => "10010")
      m_post(:finish => 4.days.ago, :start => @start, :trip => @trip, :place_string => "19104")
      @trip.posts.reload 
    end

    it "should get the date of its first post" do
      @trip.start.to_s.should == @start.to_s
    end

    it "should get the date of its last post" do
      @trip.finish.to_s.should == @finish.to_s
    end

    it "should set its bounding box based on posts" 
    
  end

  describe "validation" do
    before :each do
      @trip = Trip.new(@valid_attributes)
    end

    after :each do
      @trip.save.should == false
    end

    it "should require that the title be less than 40 characters long" do
      @trip.title = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonumm"
    end

    it "should require that the title be at least 1 character" do
      @trip.title = ""
    end

    it "should require a title" do
      @trip.title = nil
    end

    it "should require that the description be less than 255 characters long" do
      @trip.description = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commo"
    end

    it "should require a user" do
      @trip.user = nil
    end

  end

  describe "importing posts" do  

    ["3events"].each do |calendar_name|
      before :each do
        @trip = m_trip
        @posts_count = Post.count(:all)
      end

      it "should import posts from a valid ical file" do
        @trip.import_posts(File.open("#{RAILS_ROOT}/spec/fixtures/files/#{calendar_name}.ics").read)

        check_uploaded_posts(calendar_name, @posts_count, @trip.id)
      end

      it "should not recreate posts after importing once" do
        @trip.import_posts(File.open("#{RAILS_ROOT}/spec/fixtures/files/#{calendar_name}.ics").read)
        @trip.import_posts(File.open("#{RAILS_ROOT}/spec/fixtures/files/#{calendar_name}.ics").read)

        check_uploaded_posts(calendar_name, @posts_count, @trip.id)
      end

      it "should update imported posts with the same remote_ref" do
        @trip.import_posts(File.open("#{RAILS_ROOT}/spec/fixtures/files/#{calendar_name}.ics").read)
        @trip.import_posts(File.open("#{RAILS_ROOT}/spec/fixtures/files/updated_item.ics").read)

        rs_id = "f00os9eu7imojeakvj4uhd44gc@google.com"
        Post.find_by_remote_source_id(rs_id).content.should == "This just got so much cooler!"
      end

      {       {:start => DateTime.parse('2009-09-18 22:00:00 UTC')} => 2,
              {:finish => ('2009-10-07 04:00:00 UTC')} => 2,
              {:start => DateTime.parse('2009-09-18 22:00:00 UTC'), :finish => DateTime.parse('2009-10-07 04:00:00 UTC')} => 1
              }.each_pair do |date_options, count|
        it "should accept parameters restricting date range between #{date_options[:start]} to #{date_options[:finish]}" do
          @trip.import_posts(File.open("#{RAILS_ROOT}/spec/fixtures/files/#{calendar_name}.ics").read, date_options)

          Post.count(:all).should == @posts_count + count
        end
      end
    end
  end

  {
    [[1,1], [10,20], [-12,14]] => [[10,20],[-12,1]],
    [[10,15], [20,25]] => [[20,25],[10,15]],
    [[1,2]] => [[1,2],nil]
  }.each_pair do |points, expected_bounds|
    it "should generate a bounding rectangle from a collection of points (Class Method) #{points.inspect}" do
      points = points.map {|point| GeoKit::LatLng.new(point[0], point[1])}

      bounds = Trip.bounds_for(points)
      expected_bounds.each_with_index do |bound, i|
        if bound != nil
          bounds[i].lat.should be_close(bound[0], 0.001)
          bounds[i].lng.should be_close(bound[1], 0.001)
        else
          bounds[i].should be_nil
        end
      end
    end
  end
end
