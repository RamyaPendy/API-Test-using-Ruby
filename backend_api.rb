require 'rest-client'
require 'base64'

class BackendResponse
  def initialize(response)
    @response = response
  end
  
  def code
    @response.code
  end
  
  def json
    JSON.parse(@response.to_str)[0]
  end

  def json_all
    JSON.parse(@response.to_str)
  end
 
  def response_raw
    @response.to_str
  end
 
end

class BackendAPI
  def initialize(base_url, auth)
    @base_url = base_url
    @upload_url = @base_url + "upload/"
    @json_api_url = @base_url + "ayt"
    @headers_auth = {"Authorization" => "Basic " + Base64.encode64(auth) }
    @headers = {"Authorization" => "Basic " + Base64.encode64('auth header') }
  end

  def upload(filename)
    request_internal @upload_url, {:file => File.new(filename, 'rb')}, @headers
  end

  def fetch_by_id(item_type, item_id, depth)
    request_internal @json_api_url, get_item_json(item_type, item_id, depth).to_json, @headers
  end
  
  def find_by_type(item_type, depth)
    request_internal @json_api_url, find_by_type_json(item_type, depth).to_json, @headers
  end
  
  def find_by_key(item_type, key, key_value, depth)
    request_internal @json_api_url, find_by_key_json(item_type, key, key_value, depth).to_json, @headers
  end

  def find_by_key_contains(item_type, key, key_value, depth)
    request_internal @json_api_url, find_by_key_contains_json(item_type, key, key_value, depth).to_json, @headers
  end

  def create(item_type, item_value)
    request_internal @json_api_url, create_item_json(item_type, item_value).to_json, @headers
  end

  def update(item_type, item_id, item_value)
    request_internal @json_api_url, update_item_json(item_type, item_id, item_value).to_json, @headers
  end

  def request(json)
    headers = @headers_auth
    request_internal @json_api_url, json.to_json, headers
  end

  def auth(email, pass)
    response = request({"operation":"auth","type":"user","value":{"email":email,"password":pass}})

    r = response.json_all
    puts r.inspect
    raise "must have valid id" unless UUID.validate(r["meta"]["id"])
    session_id = r["meta"]["id"]

    @headers["Cookie"] = "session_id="+session_id;
  end
  
private

  def request_internal(url, payload, headers)
    resp = BackendResponse.new( RestClient::Request.execute(:method => :post, :url => url, :payload => payload, :headers => headers, :verify_ssl => false, :timeout => 600){|response, request, result| response } )
    resp
  end
  
  def get_item_json(item_type, item_id, depth)
    {
        :operation => "read",
        :type => item_type,
        :depth => depth,
        :id => item_id
    }
  end
  
  def find_by_type_json(item_type, depth)
    {
        :operation => "read",
        :type => item_type,
        :depth => depth
    }
  end

  def find_by_key_json(item_type, key, key_value, depth)
    {
        :operation => "read",
        :type => item_type,
        :depth => depth,
        :filter => [{
            :key =>  key,
            :operator => "=",
            :value => key_value
        }]
    }
  end
  
  def find_by_key_contains_json(item_type, key, key_value, depth)
    {
        :operation => "read",
        :type => item_type,
        :depth => depth,
        :filter => [{
            :key =>  key,
            :operator => "contains",
            :value => key_value
        }]
    }
  end

  def create_item_json(item_type, item_value)
    {
        :operation => "create",
        :type => item_type,
        :value => item_value
    }
  end

  def update_item_json(item_type, item_id, item_value)
    {
      :operation => "update",
      :type => item_type,
      :change => item_value,
      :filter => [{
        :key => "id",
        :operator => "=",
        :value => item_id
      }]
    }
  end
end

  return input unless input.is_a?(Hash)

  if input["meta"].present?
    key_has_meta = false
    input.each do |key,value|
      if value.is_a?(Array)
        value.each do |v|
          key_has_meta = true if v["meta"].present?
        end
      elsif value.is_a?(Hash)
        key_has_meta = true if value["meta"].present?
      end
    end

    if !key_has_meta
      return input["meta"]["id"]
    end
  end

  output = {}
  input.each { |key,value|
    if key == "meta" # replacing meta section with an id
        output["id"] = value["id"]
    else
      output[key] = make_shallow(value)
    end
  }
  output
end

def include_json(data_in, etalon_in)
  return false unless data_in.class == etalon_in.class

  if data_in.is_a? Hash
    data = data_in.clone
    data.symbolize_keys! if data.is_a? Hash

    etalon = etalon_in.clone
    etalon.symbolize_keys! if etalon.is_a? Hash

    etalon.each do |k,v|
      return false unless include_json(data[k],etalon[k])
    end
  else
    return false unless data_in == etalon_in
  end
  return true
end

