require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TripsController do
  before :each do
    @valid_params = {:trip =>{:title => "test", :description => "blah"}}
  end
  describe "create/edit a trip from valid post data" do
    before :each do
      login_as :quentin
    end

    it "should create a trip from valid data" do
      trip = mock_model(Trip)
      Trip.should_receive(:new).and_return(trip)
      trip.should_receive(:user=)
      trip.should_receive(:save).and_return(true)

      post :create, @valid_params

      response.should be_success  
    end
  end

  describe "upload posts" do
    fixtures :trips
    
    ["3events"].each do |calendar_name|
      before :each do
        login_as :quentin
        @posts_count = Post.count(:all)
        @valid_upload_params = {:id => trips(:quentins_trip).id, :trip => {:ics_file => fixture_file_upload("/files/#{calendar_name}.ics"), :ics_url => ""}}
      end

      it "should upload posts from a valid file" do
        trip = mock_model(Trip)
        posts = []
        Trip.should_receive(:find).and_return(trip)
        trip.should_receive(:import_posts).with(@valid_upload_params[:trip][:ics_file]).and_return([])
        trip.should_receive(:posts).and_return(posts)
        posts.should_receive(:reload)
        trip.should_receive(:reset_bounds)
        
        post :upload_posts, @valid_upload_params

        response.should be_success
      end
    end
  end

  describe "displaying trip data" do

  end

  describe "listing trips" do

  end

  describe "deleting trips" do

  end

  describe "security" do

    [:new, :edit, :destroy, :create, :update].each do |method|
      it "should not allow access to the #{method.to_s} action unless logged in" do

      end
    end

    [:edit, :update, :destroy].each do |method|
      it "should not allow access to the #{method.to_s} action unless user is owner" do

      end
    end

  end
end
