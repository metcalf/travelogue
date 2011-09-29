# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.dirname(__FILE__) + "/../config/environment" unless defined?(RAILS_ROOT)
require 'spec/autorun'
require 'spec/rails'
require 'fastercsv'
include ActionController::TestProcess


# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  config.global_fixtures = :users
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  #
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner

  dir = File.dirname(__FILE__)
  $LOAD_PATH.unshift "#{dir}/spec_helpers"
  ActiveSupport::Dependencies.load_paths.unshift "#{dir}/spec_helpers"
  Dir["#{dir}/spec_helpers/**/*.rb"].each do |file|
    require_dependency file
  end

  config.include AuthenticatedTestHelper
  config.include Mom
end

module FlexImage
  module Model
    module ClassMethods
      def image_file_exists(file)
        # File must be a valid object
        return false if file.nil?

        # Get the size of the file.  file.size works for form-uploaded images, file.stat.size works
        # for file object created by File.open('foo.jpg', 'rb').  It must have a size > 0.
        return false if (file.respond_to?(:size) ? file.size : file.stat.size) <= 0

        # object must respond to the read method to fetch its contents.
        return false if !file.respond_to?(:read) && !file.respond_to?(:path)

        # file validation passed, return true
        true
      end
    end
  end
end

def check_uploaded_posts(calendar_name, posts_count, trip_id, remote_ref = nil)
  csv_file = FasterCSV.read("#{RAILS_ROOT}/spec/fixtures/files/#{calendar_name}.csv", :headers => true)

  Post.count(:all).should == (posts_count + csv_file.to_a.length - 1)
  errors = []

  csv_file.each do |expected_row|
    rs_id = expected_row['remote_source_id']
    post = Post.find_by_remote_source_id(rs_id)
    if(post)
      if(post.trip_id != trip_id)
        errors << "We expected a trip id of #{trip_id} but got #{post.trip_id} (#{rs_id})"
      end
      if(remote_ref && post.remote_ref != remote_ref)
        errors << "We expected a remote ref of #{remote_ref} but got #{posts.remote_ref} (#{rs_id})"
      end

      expected_row.each do |header, expected_value|
        if(header != 'remote_source_id')
          actual_value = post.send(header).to_s.format_if_numeric(5)
          expected_value = expected_value.to_s.format_if_numeric(5)
          if(actual_value != expected_value)
            errors << "For #{header.inspect}, we expected #{expected_value} but got #{actual_value} (#{rs_id})"
          end
        end
      end
    else
      errors << "The expected remote source id, #{rs_id}, was not found"
    end
  end

  raise errors.uniq.join("\n") unless errors.empty?
end