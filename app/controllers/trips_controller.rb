class TripsController < ApplicationController
  before_filter :login_required, :only => [:new, :edit, :create, :update, :destroy]
  # GET /trips
  # GET /trips.xml
  def index
    @data = @trips = Trip.all
    @show_timemap = true

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @trips }
    end
  end

  # GET /trips/1
  # GET /trips/1.xml
  def show
    @trip = Trip.find(params[:id])
    @data = Post.find(:all, :conditions => {:trip_id => @trip.id}, :order => 'photo_id IS NULL ASC, start ASC') #@trip.posts(:order => "photo_id DESC")
    @show_timemap = true
    @page_name = @trip.title

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @trip }
    end
  end

  # GET /trips/new
  # GET /trips/new.xml
  def new
    @trip = Trip.new

    respond_to do |format|
      format.html {render :action => :edit }
      format.xml  { render :xml => @trip }
    end
  end

  # GET /trips/1/edit
  def edit
    @trip = Trip.find(params[:id])
  end

  # POST /trips
  # POST /trips.xml
  def create
    @trip = Trip.new(params[:trip])
    @trip.user = current_user

    respond_to do |format|
      if @trip.save
        flash[:notice] = 'Trip was successfully created.'
        format.html { head :ok }
        format.xml  { head :ok }
      else
        format.html { render :partial => '/layouts/edit_errors', :status => 444, :locals => {:object => @trip} }
        format.xml  { render :xml => @trip.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /trips/1
  # PUT /trips/1.xml
  def update
    @trip = Trip.find(params[:id])

    respond_to do |format|
      if @trip.update_attributes(params[:trip])
        flash[:notice] = 'Trip was successfully updated.'
        format.html { head :ok }
        format.xml  { head :ok }
      else
        format.html { render :partial => '/layouts/edit_errors', :status => 444, :locals => {:object => @trip} }
        format.xml  { render :xml => @trip.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /trips/1
  # DELETE /trips/1.xml
  def destroy
    @trip = Trip.find(params[:id])
    @trip.destroy

    respond_to do |format|
      format.html { redirect_to(trips_url) }
      format.xml  { head :ok }
    end
  end

  def new_posts 
    @trip = Trip.find(params[:id])
    @page_name = "Import Posts"

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trip }
    end
  end

  def upload_posts
    @trip = Trip.find(params[:id])
    @page_name = "Fix Uploaded Posts"

    import_options = {}
    import_options[:start]  = params[:trip][:start] if params[:restrict_start]
    import_options[:finish] = params[:trip][:finish] if params[:restrict_finish]

    respond_to do |format|
      if(params[:trip][:ics_url].empty?)
        @failed = @trip.import_posts(params[:trip][:ics_file], import_options)
      else
        @failed = @trip.import_posts_url(params[:trip][:ics_url].strip, import_options)
      end
      if @failed.empty?
        @trip.posts.reload
        @trip.reset_bounds
        flash[:notice] = 'Posts were successfully imported'
        format.html { redirect_to(trip_path(@trip)) }
        format.js  { head :ok }
      else
        format.html
        format.xml  { render :xml => @trip.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new_photos 
    @trip = Trip.find(params[:id])
    @page_name = "Upload Photos"

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trip }
    end
  end
end


