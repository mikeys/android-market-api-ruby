require './market.pb'
require 'rest_client'
require 'base64'
require 'pry'

class MarketSession
  SERVICE = "android"
  URL_LOGIN = "https://www.google.com/accounts/ClientLogin";
  URL_API = "http://android.clients.google.com/market/api/ApiRequest"
  ACCOUNT_TYPE_GOOGLE = "GOOGLE"
  ACCOUNT_TYPE_HOSTED = "HOSTED"
  ACCOUNT_TYPE_HOSTED_OR_GOOGLE = "HOSTED_OR_GOOGLE"
  PROTOCOL_VERSION = 2

  def initialize
    @request = Request.new
    set_context
  end

  def set_context
    @context = RequestContext.new
    @context.isSecure = false
    @context.version = 1002
    @context.androidId = "3d57913607bef57b"
    @context.deviceAndSdkVersion = "sapphire:7"
    set_locale
    set_operator_tmobile
  end

  def set_locale
    @context.userLanguage = "en"
    @context.userCountry = "US"
  end

  def set_operator_tmobile
    @context.operatorAlpha = "T-Mobile"
    @context.simOperatorAlpha = "T-Mobile"
    @context.operatorNumeric = "310260"
    @context.simOperatorNumeric = "310260"
  end

  AUTH_PATTERN = /\nAuth=(?<auth_key>.+)\n/
  def login(email, password, options = {})
    params = {
      "Email" => email,
      "Passwd" => password,
      "service" => SERVICE,
      "accountType" => options[:account_type] || ACCOUNT_TYPE_HOSTED_OR_GOOGLE
    }

    response_body = RestClient.post(URL_LOGIN, params)
    # auth_key = AUTH_PATTERN.match(response_body)[:auth_key]
    lines = response_body.split("\n")
    line = lines.find { |line| line[0..4] == "Auth="}

    raise RuntimeError, "auth_key not found in #{response_body}" unless line

    auth_key = line[5..-1]
    # puts "With split: #{auth_key_split}"
    # auth_key = AUTH_PATTERN.match(response_body)[:auth_key]
    # puts "With regexp: #{auth_key}"

    # puts "EQUAL? #{auth_key == auth_key_split}"

    self.auth_sub_token = auth_key
  rescue StandardError => ex
    puts ex.message
    raise RuntimeError(ex)
  end

  def flush
    @request.context = @context
    resp = execute_protobuf(@request)
  end

  def append(requestGroup)
    group = Request::RequestGroup.new

    case requestGroup
    when AppsRequest
      group.appsRequest = requestGroup
    when GetImageRequest
      group.imageRequest = requestGroup
    when CommentsRequest
      group.commentsRequest = requestGroup
    when CategoriesRequest
      group.categoriesRequest = requestGroup
    else
      raise ArgumentError, "Invalid group type"
    end

    @request.context = @context
    @request.requestgroup << group
  end

# apps = AppsRequest.new
# apps.query = "birds"
# apps.startIndex = 0
# apps.entriesCount = 10
# apps.withExtendedInfo = true

  def execute_protobuf(request)
    response = execute_raw_http_query(request)
    puts response.inspect
    Response.parse(response)
  end

  def execute_raw_http_query(request)
    headers = {
      "Cookie" => "ANDROID=#{auth_sub_token}",
      "User-Agent" => "Android-Market/2 (sapphire PLAT-RC33); gzip",
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept-Charset" => "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
      "Accept" => "text/html, image/gif, image/jpeg, *; q=.2, */*; q=.2",
      "Accept-Encoding" => nil
    }

    request64 = Base64.strict_encode64(request.to_s)
    request_data = { version: PROTOCOL_VERSION, request: request64 }
    RestClient.post(URL_API, request_data, headers)
  end

  attr_reader :auth_sub_token

  def auth_sub_token=(auth_sub_token)
    @context.authSubToken = auth_sub_token
    @auth_sub_token = auth_sub_token
  end
end