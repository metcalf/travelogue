class CreateDefaultUser < ActiveRecord::Migration
#  PARAMS = {
#              :login => 'test',
#              :email => 'a@a.com',
#              :password => 'password',
#              :password_confirmation => 'password'
#
#            }
#
  def self.up
#    if RAILS_ENV == 'development'
#      user = User.create!(PARAMS.merge ({:activation_code => User.make_token}))
#      user.register!
#      user.activate!
    end
  end
#
  def self.down
#    user.find_by_login(PARAMS[:login]).destroy
#  end
end
