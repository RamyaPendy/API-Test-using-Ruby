require 'backend_api'

$backend = BackendAPI.new("environment", "authentication")
$c = {}

def make_request(desc, expect_scope)
  if !desc.key?(:request)
    desc[:callback].call
    return
  end

  request = nil
  if desc[:request].respond_to? :call
    request = desc[:request].call
  else
    request = desc[:request]
  end

  response = $backend.request(request)

  return unless desc[:response].present?

  if request[:operation] == "count"
    json = response.response_raw
  else
    json = response.json_all
  end
  puts json.inspect.slice(0..600)

  raise "response code is wrong #{response.code}" unless response.code == desc[:response][:expected_code]

  error_name = nil

  if json.kind_of?(Array)
    error_name = nil
  else
    error_name = json["error"].nil?? nil : json["error"]["name"]
  end

  raise ("unexpected error " + error_name.to_s + " should be " + desc[:response][:expected_error].to_s) unless error_name == desc[:response][:expected_error]

  if (desc[:response][:json_validator].present?)
    desc[:response][:json_validator].call(json)
  end
end
