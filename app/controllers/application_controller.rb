# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem 
  layout proc { |ctrl|
    if(ctrl.controller_name == "trips" && ['index', 'show', 'upload_posts'].include?(ctrl.action_name) )
        'application'
      else
        nil
      end
    }

  helper :all # include all helpers, all the time
  public :render_to_string # so we can use it in our helpers

  protect_from_forgery :except => :upload_photo # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

    # when using this, remember to add "and return" in your controller:
  #   respond_not_found and return
  def respond_not_found
    render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
  end

  # when using this, remember to add "and return" in your controller:
  #   respond_bad_request and return
  def respond_bad_request(message)
    render :text => message, :status => 400
  end

  # complain if keys missing, or if values are nil
  def with_required_params(*required, &block)
    missing = required.flatten.map{|elem| elem.to_s} - params.delete_if{|k, v| v.nil?}.keys.map{|k| k.to_s}
    missing.empty? ? yield : respond_bad_request("Missing required parameters: #{missing.join(', ')}")
  end

  def check_owner(model, id)  
    # Model must exist and be owned by the current user
    if (!model.exists?(id) || !model.exists?(:id => id, :user_id => current_user.id))
      access_denied
    end
  end
end
