ActionController::Routing::Routes.draw do |map|
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate'
  map.resources :users

  map.new_posts    'trips/:id/new_posts',    :controller => 'trips', :action => 'new_posts',    :conditions => {:method => :get}
  map.upload_posts 'trips/:id/upload_posts', :controller => 'trips', :action => 'upload_posts', :conditions => {:method => :post}

  map.new_photos    '/trips/new_photos',    :controller => 'trips', :action => 'new_photos',    :conditions => {:method => :get}
  map.upload_photos '/trips/upload_photos', :controller => 'trips', :action => 'upload_photos', :conditions => {:method => :post}
  map.resources :trips

  map.new_photo    '/posts/new_photo',    :controller => 'posts', :action => 'new_photo',    :conditions => {:method => :get}
  map.upload_photo '/posts/upload_photo', :controller => 'posts', :action => 'upload_photo', :conditions => {:method => :post}
  map.edit_photo   '/posts/:id/edit_photo',:controller => 'posts', :action => 'edit_photo',   :conditions => {:method => :get}
  map.resources :posts


  map.resource :session

  map.root :controller => 'trips', :action => 'index'
  #map.resources :photos

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"
end
