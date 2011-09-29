# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  TIME_FORMAT = "%I:%M %p"
  DATE_FORMAT = "%B %d, %Y"
  DATETIME_FORMAT = DATE_FORMAT + " at " + TIME_FORMAT
  PICTURE_OVERLAP_TIME = 3000

  def menu_parameters
    menu = []
    if logged_in?
      if(action_name == 'index')
        menu << (link_to 'New trip', 'javascript:void(0)', :onclick => "iBox.showURL('#{new_trip_path}', 'Create a New Trip');")
      else
        menu << (link_to 'More Trips', trips_path) 
        edit_menu = [
          'Edit...',
          (link_to 'Edit Trip', 'javascript:void(0)', :onclick => "iBox.showURL('#{edit_trip_path(@trip)}', 'Edit Trip');"),
          (link_to 'New Post','javascript:void(0)', :onclick => "iBox.showURL('#{new_post_path(:trip_id => @trip.id)}','New Post');"),
          (link_to 'Upload Photos','javascript:void(0)', :onclick => "iBox.showURL('#{new_photos_path(:id => @trip.id)}','Upload Photos',{width : '900px'});"),
          (link_to 'Upload Posts','javascript:void(0)', :onclick => "iBox.showURL('#{ new_posts_path(@trip)}','Import Posts');")
        ]
        menu << edit_menu
      end
      trips_menu = current_user.trips.map {|trip| (link_to trip.title, trip_path(trip))}
      menu << ([(link_to 'My Trips', trips_path)] + trips_menu)
      menu << (link_to_remote "Log out", :url => logout_path, :success => "window.location.reload()", :title => "Log out")
    else
      menu << (link_to "Log in", "javascript:void(0)", :onclick => "iBox.showURL('#{login_path}','Log In');")
      menu << (link_to "Sign up", "javascript:void(0)", :onclick => "iBox.showURL('#{signup_path}','Sign Up For a Free Account');", :title => "Create an account")
    end

    menu
  end

  def timeline_values_array(data)
    last_start = nil
    last_locations = nil
    last_id = nil
    multi_photo_ids = []
    result = data.map do |post|
      if(post.respond_to?(:photo) && post.photo)
        if(last_start and last_locations and
                (last_start > post.start) and post.locations_eql?(last_locations))
          value = nil
          multi_photo_ids << last_id
        else
          value = timeline_value(post)
          last_start = post.start+PICTURE_OVERLAP_TIME
          last_locations = post.locations
          last_id = post.id
        end
      else
        value = timeline_value(post)
      end

      value
    end
    
    result = result.compact.to_json
    result.gsub!(/"(getImageTheme\(.+?\))"/) {|match| "#{$1}"}

    if(!multi_photo_ids.empty?)
      multi_photo_ids.uniq!
      multi_photo_ids.each {|post_id| result.gsub!(post_path(post_id, :jpg),post_path(post_id, :html, :photo_group => 1))}
    end

    result
  end

  def timeline_value(post)
    return nil unless post.start || post.finish || !post.bounds.empty?
    title = post.title
    if title.length > 22
      title = title[0,20].strip + "..."
    end
    value = {
              :id       => post.id,
              :start    => post.start,
              :title    => title,
              :options  => {}
            }
    value[:start] = post.start if post.start
    value[:end] = post.finish if post.finish != nil
    if(post.respond_to?(:summary))
      value[:options][:infoHtml] = controller.render_to_string :partial => 'trips/summary_window', :locals => {:trip => post}
    else
      value[:options][:infoHtml] = controller.render_to_string :partial => 'posts/show_inline', :locals => {:post => post}
      if(post.photo)
        value[:options][:infoUrl] = post_path(post.id, :jpg)
        value[:title] = ""
      else
        value[:options][:infoUrl] = post_path(post)
      end
    end

    if(post.respond_to?(:bounds))
      bounds = post.bounds_for_google
      if(bounds)
        if(bounds.length > 2)
          value[:polygon] = bounds
        else(bounds.length )
          value[:point] = bounds
        end 
      end

    else
      if(post.locations.length == 1)
        value[:point] = {:lat => post.locations.first.lat, :lon => post.locations.first.lng}
      elsif(post.locations.length > 1)
        value[:polyline] = post.locations.map {|loc| {:lon => loc.lng, :lat => loc.lat}}
      end

      if(post.respond_to?(:photo) && post.photo)
        value[:options][:theme] = "getImageTheme('#{post_path(post, :png)}')"
      end
    end

    value
  end

  def info_window_functions(post)
    result = ""
    if(post.respond_to?(:content))
      result += "openInfoWindow: TimeMapItem.openInfoWindowLightboxAjax ,
                closeInfoWindow: TimeMapItem.closeInfoWindowLightbox,"
    end
    result
  end

  def circle_polygon(lat, lng, radius)
    d = radius/3959 # Assumes radius in miles, radians
    latR = lat.radians
	lngR = lng.radians

    latOffset = latR

    (0..360).map do |index|
      tc = index.radians
      y  = Math.asin(Math.sin(latR)*Math.cos(d)+Math.cos(latR)*Math.sin(d)*Math.cos(tc))
      dlng = Math.atan2(Math.sin(tc)*Math.sin(d)*Math.cos(latR),Math.cos(d)-Math.sin(latR)*Math.sin(y))
      x = ((lngR-dlng+Math::PI) % (2*Math::PI)) - Math::PI

      {"lat" => y.degrees, "lon" => x.degrees}
    end
  end

  def page_title_helper
    "Travelogue" +
      ([ 'test', 'production' ].include?(RAILS_ENV) ? '' : " [#{RAILS_ENV}]") +
      ": " + page_name
  end

  def page_name
    if @page_name.blank?
      model_name = controller.controller_name.singularize
      pretty_model_name = controller.controller_name.singularize.titleize
      @page_name =
        case controller.action_name
          when 'index'
            controller_name.titleize
          when 'new', 'create'
            "New #{pretty_model_name}"
          when 'show', 'edit', 'update'
            title = action_name == 'show' ? '' : 'Editing'
            title += " #{pretty_model_name}"
            # See if we can find one of these things as @thing, that responds to #name
            if model = instance_variable_get("@#{model_name.downcase}".to_sym)
              title += " '#{model.name}'" if model.respond_to?(:name)
            end
            title
          else
            if(@action_title)
              @action_title
            else
              raise "Unable to intuit page title, you must set @page_title in your view or controller for this page"
            end
        end
    end

    @page_name
  end

  def form_success(id)
    form_up = "Effect.BlindUp('editor_#{id}');"
    success_down = "Effect.BlindDown('success_#{id}');"
    failure_up = "Effect.BlindUp('failure_#{id}');"

    form_up + success_down + failure_up
  end

  def form_failure(id)
    "Effect.BlindDown('failure_#{id}');"
  end

  def date_range(start, finish)
    if(start.year == finish.year)
      if(start.year == finish.year && start.yday == finish.yday)
        return "#{start.strftime(TIME_FORMAT)} and #{finish.strftime(TIME_FORMAT)} on #{start.strftime(DATE_FORMAT)}"
      else
        return "#{start.strftime(DATETIME_FORMAT.sub(", %Y",''))} and #{finish.strftime(DATETIME_FORMAT)}"
      end
    else
      return "#{start.strftime(DATETIME_FORMAT)} and #{finish.strftime(DATETIME_FORMAT)}"
    end

  end
end
