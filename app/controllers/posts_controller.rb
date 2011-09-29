class PostsController < ApplicationController
  RESTRICTED = [:new, :edit, :create, :update, :destroy, :new_photo, :upload_photo]
  before_filter :login_required, :only => RESTRICTED
  before_filter :check_ownerships, :only => RESTRICTED

  # GET /posts
  # GET /posts.xml
  def index
    @posts = Post.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @posts }
    end
  end

  # GET /posts/1
  # GET /posts/1.xml
  def show
    @post = Post.find(params[:id])
    respond_to do |format|
      if(params.has_key?(:map))
        @posts = find_posts_at(@post.locations, @post.trip)

        @photos = @posts.select {|post|  post.photo}
        @posts  = @posts.select {|post| !post.photo}
      elsif(params[:photo_group])
        posts = find_posts_at(@post.locations, @post.trip)

        @photos = posts.select {|post| post.photo and post.start >= @post.start and post.start <= (@post.start+ApplicationHelper::PICTURE_OVERLAP_TIME)}
        @posts = []    
      else
        @posts = [@post]
      end

      if(@posts.length == 1 and !@posts.first.photo)
        @photos = Post.find(:all, :conditions => ['photo_id IS NOT NULL and trip_id = ? and ((start > ? and start < ?) or title = ?)', @posts.first.trip.id, @posts.first.start, @posts.first.finish, @posts.first.title])
      elsif(!@photos)
        @photos = []  
      end

      if(params[:size] == 'small')
        format.jpg  {render :partial => 'posts/show_small'}
      elsif(@posts.length == 1 and @posts.first.photo)
        format.jpg  { render :layout => false}
      else
        format.jpg  {render :partial => 'posts/show_group.html.haml' }
      end

      format.html { render :partial => 'posts/show_group.html.haml'}
      format.png  { render :layout => false}
    end
  end

  # GET /posts/new
  # GET /posts/new.xml
  def new
    with_required_params(:trip_id) do
      @post = Post.new(:trip_id => params[:trip_id])
      respond_to do |format|
        format.html { render :partial => 'posts/post_editor', :locals => {:post => @post, :redirect => true}}
        format.xml  { render :xml => @post }
      end
    end
  end

  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
    respond_to do |format|
      format.html { render :partial => 'posts/post_editor', :locals => {:post => @post, :redirect => true}}
    end
  end

  # POST /posts
  # POST /posts.xml
  def create
    @post = Post.new(params[:post])

    respond_to do |format|
      if @post.save
        flash[:notice] = 'Post was successfully created.'
        @post.trip.reset_bounds
        format.html { head :ok }
        format.xml  { render :xml => @post, :status => :created, :location => @post }
      else
        format.html { render :partial => '/layouts/edit_errors', :status => 444, :locals => {:object => @post} }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /posts/1
  # PUT /posts/1.xml
  def update
    @post = Post.find(params[:id])
    post_params = params[:post]

    # Calendar based forms pass the datetimes as strings
    if(post_params.has_key?(:start) and post_params[:start].kind_of?(String))
      post_params[:start] = DateTime.parse(post_params[:start])
    end
    if(post_params.has_key?(:finish) and post_params[:finish].kind_of?(String))
      post_params[:finish] = DateTime.parse(post_params[:finish])
    end
    
    if(params.has_key?(:mode))
      if(params[:mode] == 'set')
        post_params.delete(:closest_post_id)
      else
        nearest_post = Post.find(params[:post].delete(:closest_post_id))

        post_params.delete(:place_string)
        @post.place_string = nearest_post.place_string 
        diff = nearest_post.point_time - @post.start
        @post.start = nearest_post.point_time
        @post.title = nearest_post.title

        post_params.delete_if {|key, val| key.index("start")}
        if(params.has_key?(:autoupdate) and params[:autoupdate] == "1")
          @post.album.each do |post|
            post.place_string = nil
            post.start = post.start + diff
            post.title = post.closest_post.title
            post.save!
          end
        end
      end
    end  

    respond_to do |format|
      if @post.update_attributes(post_params)
        flash[:notice] = 'Post was successfully updated.'
        @post.trip.reset_bounds
        format.html  { head :ok }
        format.xml  { head :ok }
      else
        format.html { render :partial => '/layouts/edit_errors', :status => 444, :locals => {:object => @post} }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy
    @post = Post.find(params[:id])
    @post.destroy

    respond_to do |format|
      format.html { redirect_to(trip_url(@post.trip)) }
      format.xml  { head :ok }
    end
  end

  def new_photo
    with_required_params(:trip_id) do
      @action_title = "Upload Photo"
      @post = Post.new
      @trip_id = params[:trip_id]
      respond_to do |format|
        format.html
        format.xml  { render :xml => @post }
      end
    end
  end

  def upload_photo
    with_required_params(:post) do
      if(params.has_key?(:mass_upload))
        filename = params.keys.select {|key| !key.scan(/jpg|jpeg|gif|png/i).empty? }.first
        image = params[filename]
        taken = parse_exif_string(params[:exif])
      else
        image = params[:post][:image_file]
        taken = datetime_taken(image)
      end

      taken ||= params[:start]
      taken ||= DateTime.now
      
      photo = Photo.new
      photo.image_file = image
      respond_to do |format|
        if(photo.save)
          @post = Post.new(:title => params[:post][:title], :trip_id => params[:post][:trip_id])
          @post.photo = photo
          @post.start = taken

          if(@post.save)
            @post.update_attribute(:created_at, params[:post][:created_at])
            flash[:notice] = 'Post was successfully created.'
            format.html  { redirect_to(trip_url(@post.trip)) }
            format.xml  { render :xml => @post, :status => :created, :location => @post }
          else
            format.html  { render :partial => '/layouts/edit_errors', :status => 444, :locals => {:object => @post} }
            format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
          end
        else
          format.html  { render :partial => '/layouts/edit_errors', :status => 444, :locals => {:object => @post} }
          format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
        end
      end

    end
  end

  def edit_photo
    @post = Post.find(params[:id])
    respond_to do |format|
      format.html { render :partial => 'posts/photo_editor', :locals => {:post => @post, :redirect => true}}
    end
  end

  private

  def check_ownerships
    check_owner(Trip, params[:trip_id]) if params.has_key?(:trip_id)
  end

  def parse_exif_string(exif)
    exif_arr = exif.split("::")
    date = exif_arr[11]
    return if date.empty?
    begin
      return DateTime.strptime(date,'%Y:%m:%d %H:%M:%S')
    rescue ArgumentError
      begin
        return DateTime.parse(date)
      rescue ArgumentError
        return nil
      end
    end
  end

  def datetime_taken(file)
    if file.path
      photo = Magick::Image.read(file.path).first
    else
      photo = Magick::Image.from_blob(file.read).first
    end
    # the get_exif_by_entry method returns in the format: [["Make", "Canon"]]
    date  = photo.get_exif_by_entry('DateTimeOriginal')[0][1]
    date  ||= photo.get_exif_by_entry('DateTimeDigitized')[0][1]
    date  ||= photo.get_exif_by_entry('DateTime')[0][1]
    return unless date

    begin
      return DateTime.strptime(date,'%Y:%m:%d %H:%M:%S')
    rescue ArgumentError
      begin
        return DateTime.parse(date)
      rescue ArgumentError
        return nil
      end
    end
  end

  def find_posts_at(locations, trip)
    # TODO: Make this suck less... maybe by  HABTM with locations?
    locs = []
    locations.each do |post_loc|
      locs += Location.find(:all, :conditions => ['post_id IS NOT NULL and lat > ? and lat < ? and lng > ? and lng < ?', post_loc.lat-0.0001, post_loc.lat+0.0001, post_loc.lng-0.0001, post_loc.lng+0.0001])
    end
    post_map = {}
    locs.each do |loc|
      post_map[loc.post_id] ||= []
      post_map[loc.post_id] << loc
    end
    post_map.delete_if { |post_id, loc_array| loc_array.length != locations.length}

    posts = Post.find(:all, :conditions => {:id => post_map.keys.uniq, :trip_id => trip.id}, :order => "start ASC, finish ASC")
    posts = posts.select {|post| post.locations.length == locations.length}

    posts
  end
end
