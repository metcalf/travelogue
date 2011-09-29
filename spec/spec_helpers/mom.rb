require 'uuidtools'
require "vendor/plugins/fleximage/test/mock_file"

module Mom
  def m_uuid
    UUID.timestamp_create().to_s.gsub('-',' ')
  end

  def m_post(options = {})
    defaults = {
              :start          => 3.days.ago,
              :title          => "My Post",
              :content        => "Lorem Ipsum",

              :place_string => "318 S 42nd St, 19104"
            }
    defaults[:finish] = 2.days.ago unless options.has_key?(:photo)
    defaults[:trip] = m_trip unless options.has_key?(:trip_id)
    Post.create!(defaults.merge(options))
  end

  def m_trip(options = {})
    defaults = {
              :title          => "My Trip",
              :description    => "It was super cool, I went to a bunch of places and stuff",
              :user           => User.find_by_login("quentin")
            }
    Trip.create!(defaults.merge(options))
  end

  def m_photo(options = {})
    if(options.has_key?(:path))
      options[:image_file] ||=  MockFile.new(options[:path])
      options.delete(:path)
    else
      options[:image_file] ||=  MockFile.new("#{RAILS_ROOT}/spec/fixtures/files/test_image.jpg")
    end

    Photo.create!(options)
  end

   def m_uploaded_image(path = "files/test_image.jpg")
    fixture_file_upload(path, "image/jpeg", :binary)
  end

  def m_passive_user(options = {})
    defaults = {
      :login                  => 'quire',
      :email                  => 'quire@example.com',
      :password               => 'quire69',
      :password_confirmation  => options[:password] ? options[:password] : 'quire69'
      }
    User.new(defaults.merge(options))
  end

  def m_user(options = {})
    do_validation = options.delete(:activate_user)
    user = m_passive_user(options)

    if do_validation
      raise "Unable to register user: #{user.errors.inspect}" unless user.register!
      raise "Unable to activate user: #{user.errors.inspect}" unless user.activate!
      raise "Invalid user: #{user.errors.inspect}" unless user.valid?
    else
      user.register! if user.valid?
    end
    user
  end
end