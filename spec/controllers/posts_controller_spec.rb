require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PostsController do
  fixtures :trips, :posts
  
  before :each do
    @valid_params       = {:post => {:title => "My Test Post!", :content => "Lorem ipsum sic amet....", :start => 2.days.ago, :trip_id => 1}}
    @valid_photo_params = {:post => {:title => "My Photo", :trip_id => 1, :image_file => MockFile.new("#{RAILS_ROOT}/spec/fixtures/files/test_image.jpg") }}
  end

  describe "show" do
    before :each do
      @post = m_post
    end

    {'html'=>'_show','jpg' => 'show.jpg.flexi'}.each_pair do |format, template|
      it "should show the post normally from the timeline" do
        get :show, :id => @post.id, :format => format

        response.should render_template("posts/#{template}")
      end

      it "should show the post normally from the map if only one post is at that location" do
        get :show, :id => @post.id, :map => 1, :format => format

        response.should render_template("posts/#{template}")
      end

      it "should show a summary of posts at the same location when the map parameter is set" do
        m_post(:trip => @post.trip)
        get :show, :id => @post.id, :map => 1, :format => format

        assigns[:posts].length.should == 2
        response.should render_template('posts/_show_group')
      end

      it "should not show posts with more locations" do
        m_post(:trip => @post.trip)
        m_post(:trip => @post.trip, :place_string => @post.place_string  + "; San Francisco, CA")

        get :show, :id => @post.id, :map => 1, :format => format

        assigns[:posts].length.should == 2
        response.should render_template('posts/_show_group')
      end

      it "should find photos to show alongside posts without a group" do
        m_post(:trip => @post.trip, :photo => m_photo)

        get :show, :id => @post.id, :format => format

        assigns[:photos].length.should == 1
        response.should render_template("posts/#{template}")
      end

      it "should find photos to show alongside posts without a group from the map" do
        m_post(:trip => @post.trip, :photo => m_photo)

        get :show, :id => @post.id, :map => 1, :format => format

        assigns[:photos].length.should == 1
        response.should render_template("posts/#{template}")
      end

      it "should find photos to show alongside posts in a group" do
        m_post(:trip => @post.trip)
        m_post(:trip => @post.trip, :photo => m_photo)

        get :show, :id => @post.id, :map => 1, :format => format

        assigns[:photos].length.should == 1
        assigns[:posts].length.should == 2
        response.should render_template('posts/_show_group')
      end

    end
  end

  describe "CRUD" do
    before :each do
      login_as :quentin
    end

    describe "new" do
      it "should load the new post page" do
        get :new, :trip_id => trips(:quentins_trip).id
        response.should be_success
      end

      it "should require a trip_id parameter" do
        get :new
        response.should_not be_success
      end
    end

    describe "index" do
      it "should load all posts" do
        get :index
        response.should be_success
        assigns(:posts).length.should == 1    
      end
    end

    describe "create" do

      it "should create a post from valid parameters" do

        post :create, @valid_params

        response.should be_success
        _post = Post.find_by_title("My Test Post!")
        _post.should_not be_nil
        _post.trip_id.should == @valid_params[:post][:trip_id]
        _post.locations.empty?.should be_true
      end

      it "should create a post from valid parameters with geolocation" do
        params = @valid_params
        params[:post][:place_string] = "10010"
        post :create, params

        response.should be_success
        _post = Post.find_by_title("My Test Post!")
        _post.should_not be_nil
        _post.locations.empty?.should be_false
      end
      
      it "should create a trip from valid parameters with an end date" do
        params = @valid_params
        params[:post][:finish] = 1.days.ago
        post :create, params

        response.should be_success
        _post = Post.find_by_title("My Test Post!")
        _post.should_not be_nil
        _post.finish.to_s.should == params[:post][:finish].to_s
      end
    end

    describe "destroy" do
      it "should redirect to the trip page" do
        _post = m_post

        post :destroy, :id => _post.id

        response.should redirect_to(:controller => :trips, :action => :show, :id => _post.trip.id)
      end
    end
  end

  describe "photos" do
    before :each do
      login_as :quentin
    end

    describe "new_photo" do
      it "should load the new photo page" do
        get :new_photo, :trip_id => trips(:quentins_trip).id
        response.should be_success
      end

      it "should require a trip_id parameter" do
        get :new_photo
        response.should_not be_success
      end
    end

    describe "upload_photo" do
      it "should upload a valid photo" do
        post :upload_photo, @valid_photo_params

        response.should redirect_to(:controller => :trips, :action => :show, :id => @valid_photo_params[:post][:trip_id])
        _post = Post.find_by_title("My Photo")
        _post.should_not be_nil   
      end

      it "should get the timestamp from the photo" do
        post :upload_photo, @valid_photo_params

        response.should redirect_to(:controller => :trips, :action => :show, :id => @valid_photo_params[:post][:trip_id])
        _post = Post.find_by_title("My Photo")
        _post.start.to_s.should == "2008-04-11 16:20:11 UTC"
      end
    end

    describe "update photo" do
      before :each do 
        @valid_params[:post].delete(:content)
        @post = m_post(:photo => m_photo)
        @valid_params[:id] = @post.id
        @valid_params[:post][:place_string] = "Buenos Aires, Argentina"

        @other_post = m_post
        @valid_params[:post][:closest_post_id] = @other_post.id
      end

      it "should update the data correctly in set mode" do
        @valid_params[:mode] = 'set'
        _post = Post.exists?(:title=>"My Test Post!").should be_false

        put :update, @valid_params

        response.should be_success
        _post = Post.find_by_title("My Test Post!")
        _post.should_not be_nil
        _post.place_string.should == "Buenos Aires, Argentina"
        _post.start.to_s.should == @valid_params[:post][:start].to_s
      end

      it "should update the data correctly in guess mode" do
        @valid_params[:mode] = 'guess'

        put :update, @valid_params

        response.should be_success
        _post = Post.find_by_title("My Test Post!")
        _post.should_not be_nil
        _post.place_string.should == @other_post.place_string
        _post.start.to_s.should == @other_post.point_time.to_s
      end
      
    end
  end

  describe "mass photo upload" do
    before :each do
      @image = @valid_photo_params[:post].delete(:image_file)
      @valid_photo_params[:post][:title] = ''
      @valid_photo_params[:exif] = "::sRGB::JPEG (old-style)::2 bits-pixel::0 EV::Auto exposure::::Flash did not fire, auto::6.6 mm::Canon::Canon PowerShot SD970 IS::2009:05:25 03:37:48::180 dots per inch::180 dots per inch::2448::3264::1-500 sec"
      @valid_photo_params.merge!({:user_id => users(:quentin).id, :secret => users(:quentin).secret, :mass_upload => "-----"})
    end

    it "should allow post with a valid secret" do
      post :upload_photo, @valid_photo_params.merge({"test.jpg" => @image})

      response.should redirect_to(:controller => :trips, :action => :show, :id => @valid_photo_params[:post][:trip_id])
    end

    it "should not allow post with an invalid secret" do
      post :upload_photo, @valid_photo_params.merge({"test.jpg" => @image, :secret => "blah"})

      response.should redirect_to(:controller => :sessions, :action => :new)
    end

    ['blah.JPG','5_x_y.jpeg','ewqoekd&$.gif','test.GIF','another.PNG','yep.png'].each do |filename|
      it "should allow a post with a valid filename" do
        post :upload_photo, @valid_photo_params.merge({filename => @image})

        response.should redirect_to(:controller => :trips, :action => :show, :id => @valid_photo_params[:post][:trip_id])
      end
    end

  end

  describe "security" do

    [:new, :edit, :destroy, :create, :update].each do |method|
      it "should not allow access to the #{method.to_s} action unless logged in" do
      end
      
      it "should not allow access to the #{method.to_s} action unless user is the owner" do
      end
    end

  end

end
