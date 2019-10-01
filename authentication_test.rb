require 'recursive-open-struct'
require 'spec_helper'
require "rspec/json_expectations"
require 'uuid'
require 'autolaunch.rb'

tests = [
{
  :text => 'tried to register consumer user2, in case it was not registered yet',
  :request => {
    :type => 'user', :operation => 'register',
    :value => {:email => "test@test.com", :password => "test123", :name => "test" }
  }
},
{
  :text => 'email/pass succeeds as expected',
  :request => {
    :type => 'user', :operation => 'auth',
    :value => {:email => "test@test.com", :password => "test123" }
  },
  :response => {
    :expected_code => 200, :expected_error => nil,
    :json_validator => lambda { |r|
      raise "must have valid id" unless UUID.validate(r["meta"]["id"])
      $c["session_id"] = r["meta"]["id"]
    }
  }
},
{
  :text => 'auth without email failed as expected',
  :request => {
    :type => 'user', :operation => 'auth',
    :value => {:password => "test123" }
  },
  :response => {
    :expected_code => 400, :expected_error => 'REQUIRED_CONSTRAINT_VIOLATION'
  }
},
{
  :text => 'auth without password failed as expected',
  :request => {
    :type => 'user', :operation => 'auth',
    :value => {:email => "test@test.com"}
  },
  :response => {
    :expected_code => 400, :expected_error => 'REQUIRED_CONSTRAINT_VIOLATION'
  }
},
{
  :text => 'auth with empty input failed as expected',
  :request => {
    :type => 'user', :operation => 'auth',
    :value => {}
  },
  :response => {
    :expected_code => 400, :expected_error => 'REQUIRED_CONSTRAINT_VIOLATION'
  }
},
]

describe 'User' do
  context 'authentication:' do
    tests.each do |t|
      it t[:text] do
        make_request(t, self)
      end
    end
  end
end


