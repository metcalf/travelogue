require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Photo do

  before :each do
    @valid_attributes = { :image_file => MockFile.new("#{RAILS_ROOT}/spec/fixtures/files/test_image.jpg") }
  end
  it "should create a new instance given valid attributes" do
    Photo.create!(@valid_attributes)
  end

  describe "basic attributes" do

    before :each do
      @photo = Photo.create!(@valid_attributes)
    end

    it "should set width and height correctly" do
      @photo.image_width.should == 100
      @photo.image_height.should == 110
    end
  end

  describe "validation" do
    before :each do
      @photo = Photo.new(@valid_attributes)
    end

    after :each do
      @photo.save.should == false
    end

    #it "should require an image file" do
    #  @photo.image_file = nil
    #end

  end
end
