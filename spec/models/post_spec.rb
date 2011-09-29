require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Post do
  fixtures :trips

  before :each do
    @valid_attributes = {
      :start => 36.hours.ago,
      :title => "Post Title",
      :trip => trips(:quentins_trip)
    }
  end 

  it "should create a new instance given valid attributes" do
    Post.create!(@valid_attributes)
  end

  describe "basic attributes" do
    before(:each) do
      @post = Post.new(@valid_attributes)
    end

    after :each do
      @post.save!
    end

    it "should accept an end datetime" do
      @post.finish = 1.days.ago.to_s
    end

    it "should accept content" do
      @post.content = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commo"
    end

  end

  describe "geolocation" do
    before(:each) do
      @post = Post.new(@valid_attributes.merge({:place_string => "10010"}))
    end

    it "should geolocate" do
      @post.save!
      @post.locations.first.lat.should be_close(40.7388,  0.001)
      @post.locations.first.lng.should be_close(-73.9815, 0.001)
    end

    it "should recenter the trip"
  end

  describe "photo posts" do
    before :each do
      @other_post = m_post(:place_string => "Buenos Aires, Argentina", :trip => @valid_attributes[:trip])
      @photo = m_photo

    end

    it "should guess a location based on nearby posts" do
      post = Post.create!(@valid_attributes.merge({:photo => @photo}))

      post.locations.first.lng.should be_close(@other_post.locations.first.lng, 0.001)
      post.locations.first.lat.should be_close(@other_post.locations.first.lat, 0.001)
    end

    it "should not overwrite a guessed location after it has been set" do
      post = Post.create!(@valid_attributes.merge({:photo => @photo, :place_string => @other_post.place_string}))
      better_post = m_post(:start => 1.days.ago, :finish => 2.hours.ago, :place_string => "10010", :trip => @valid_attributes[:trip])

      post.save!

      post.locations.first.lng.should be_close(@other_post.locations.first.lng, 0.001)
      post.locations.first.lat.should be_close(@other_post.locations.first.lat, 0.001)
    end

    [[2.days.ago, 1.hours.ago], [2.days.ago, 37.hours.ago], [35.hours.ago, 1.days.ago]].each do |times|
      it "should prefer the best guess" do
        better_post = m_post(:start => times[0], :finish => times[1], :place_string => "10010", :trip => @valid_attributes[:trip])
        post = Post.create!(@valid_attributes.merge({:photo => @photo}))

        post.locations.first.lng.should be_close(better_post.locations.first.lng, 0.001)
        post.locations.first.lat.should be_close(better_post.locations.first.lat, 0.001)
      end
    end

    it "should get its album" do
      created = Time.now
      posts = [m_post(:photo => m_photo, :created_at => created),m_post(:photo => m_photo, :created_at => created)]
      post = Post.create!(@valid_attributes.merge({:photo => @photo, :created_at => created}))
      post.album.length.should == 3
    end

  end 

  describe "validation" do
    before(:each) do
      @post = Post.new(@valid_attributes)
    end

    after(:each) do
      @post.save.should == false
    end

    it "should require that end datetime be after start datetime" do
      @post.finish = 2.days.ago.to_s
    end

    it "should require a start time" do
      @post.start = nil
    end

    it "should require that the title be less than 255 characters long" do
      @post.title = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commo"
    end

    it "should require that the title be at least 1 character" do
      @post.title = ""
    end

    it "should require a trip" do
      @post.trip = nil
    end

    it "should require a valid place string if one is included" do
      @post.place_string = "sdciaodjcoidscoisj"
    end

  end

  { 10.hours.ago    => [2.hours.ago, 18.hours.ago],
      2.days.ago      => [1.days.ago,  3.days.ago],
      200.minutes.ago => [90.minutes.ago, 310.minutes.ago]
            }.each_pair do |result, times|
      it "should generate the correct point time" do
        @valid_attributes.merge!(:start => times[0], :finish => times[1])
        Post.new(@valid_attributes).point_time.to_s.should == result.to_s
      end
  end
end
