require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  describe "route generation" do
    it "should route users's 'index' action correctly" do
      route_for(:controller => 'users', :action => 'index').should == "/users"
    end

    it "should route users's 'new' action correctly" do
      route_for(:controller => 'users', :action => 'new').should == "/signup"
    end

    it "should route {:controller => 'users', :action => 'create'} correctly" do
      route_for(:controller => 'users', :action => 'create').should == "/register"
    end

    it "should route users's 'show' action correctly" do
      route_for(:controller => 'users', :action => 'show', :id => '1').should == "/users/1"
    end

    it "should route users's 'edit' action correctly" do
      route_for(:controller => 'users', :action => 'edit', :id => '1').should == "/users/1/edit"
    end

    it "should route users's 'update' action correctly" do
      #route_for(:controller => 'users', :action => 'update', :id => '1').should == "/users/1"
    end

    it "should route users's 'destroy' action correctly" do
      #route_for(:controller => 'users', :action => 'destroy', :id => '1').should == "/users/1"
    end

    it "should route user's activate action correctly" do
      route_for(:controller => 'users', :action => 'activate', :activation_code => '2').should == "/activate/2"
    end
  end

  describe "route recognition" do
    it "should generate params for users's new action from GET /users" do
      params_from(:get, '/users/new').should == {:controller => 'users', :action => 'new'}
      params_from(:get, '/users/new.xml').should == {:controller => 'users', :action => 'new', :format => 'xml'}
      params_from(:get, '/users/new.json').should == {:controller => 'users', :action => 'new', :format => 'json'}
    end

    it "should generate params for users's create action from POST /users" do
      params_from(:post, '/users').should == {:controller => 'users', :action => 'create'}
      params_from(:post, '/users.xml').should == {:controller => 'users', :action => 'create', :format => 'xml'}
      params_from(:post, '/users.json').should == {:controller => 'users', :action => 'create', :format => 'json'}
    end

    it "should generate params for user's show action from GET /users/1" do
      params_from(:get, '/users/1').should == {:controller => 'users', :action => 'show', :id => '1'}
    end

    it "should generate params for users's edit action from GET /users/1/edit" do
      params_from(:get , '/users/1/edit').should == {:controller => 'users', :action => 'edit', :id => '1'}
    end

    it "should generate params {:controller => 'users', :action => update', :id => '1'} from PUT /users/1" do
      params_from(:put , '/users/1').should == {:controller => 'users', :action => 'update', :id => '1'}
      params_from(:put , '/users/1.xml').should == {:controller => 'users', :action => 'update', :id => '1', :format => 'xml'}
      params_from(:put , '/users/1.json').should == {:controller => 'users', :action => 'update', :id => '1', :format => 'json'}
    end

    it "should generate params for users's destroy action from DELETE /users/1" do
      params_from(:delete, '/users/1').should == {:controller => 'users', :action => 'destroy', :id => '1'}
      params_from(:delete, '/users/1.xml').should == {:controller => 'users', :action => 'destroy', :id => '1', :format => 'xml'}
      params_from(:delete, '/users/1.json').should == {:controller => 'users', :action => 'destroy', :id => '1', :format => 'json'}
    end

    it "should generate params for user's activate action from GET users/1/2" do
      params_from(:get, '/activate/2').should == {:controller => 'users', :action => 'activate', :activation_code => '2'}
    end
  end

  describe "named routing" do
    before(:each) do
      get :new
    end

    it "should route users_path() to /users" do
      users_path().should == "/users"
      users_path(:format => 'xml').should == "/users.xml"
      users_path(:format => 'json').should == "/users.json"
    end

    it "should route new_user_path() to /users/new" do
      new_user_path().should == "/users/new"
      new_user_path(:format => 'xml').should == "/users/new.xml"
      new_user_path(:format => 'json').should == "/users/new.json"
    end

    it "should route user_(:id => '1') to /users/1" do
      user_path(:id => '1').should == "/users/1"
      user_path(:id => '1', :format => 'xml').should == "/users/1.xml"
      user_path(:id => '1', :format => 'json').should == "/users/1.json"
    end

    it "should route edit_user_path(:id => '1') to /users/1/edit" do
      edit_user_path(:id => '1').should == "/users/1/edit"
    end
  end

end