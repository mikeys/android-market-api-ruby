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
    @context.version = 8013013
    @context.androidId = "3d57913607bef57b"
    @context.deviceAndSdkVersion = "crespo:15"
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
    auth_key = AUTH_PATTERN.match(response_body)[:auth_key]

    unless auth_key
      raise RuntimeError, "auth_key not found in #{response_body}"
    end

    self.auth_sub_token = auth_key
  rescue StandardError => ex
    puts ex.message
    raise RuntimeError(ex)
  end

  def execute(request_group)
    request = Request.new
    request.context = @context
    request.requestgroup << request_group

    execute_protobuf(request)
  end

  def execute_protobuf(request)
    response = execute_raw_http_query(request)
    Response.parse(response)
  end

  def execute_raw_http_query(request)
    headers = {
      "Cookie" => "ANDROID=#{auth_sub_token}",
      "User-Agent" => "Android-Finsky/3.7.13 (api=3,versionCode=8013013,sdk=15,device=crespo,hardware=herring,product=soju); gzip",
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept-Charset" => "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
      "Accept-Encoding" => nil
    }

    request64 = Base64.urlsafe_encode64(request.to_s)
    request_data = { version: PROTOCOL_VERSION, request: request64 }
    RestClient.post(URL_API, request_data, headers)
  end

  def android_id
    @context.android_id
  end

  def android_id=(android_id)
    @context.androidId = android_id
  end

  attr_reader :auth_sub_token

  def auth_sub_token=(auth_sub_token)
    @context.authSubToken = auth_sub_token
    @auth_sub_token = auth_sub_token
  end

  module Helper
    class << self
      def build_request_group_for(request_element)
        group = Request::RequestGroup.new

        case request_element
        when AppsRequest
          group.appsRequest = request_element
        when GetImageRequest
          group.imageRequest = request_element
        when CommentsRequest
          group.commentsRequest = request_element
        when CategoriesRequest
          group.categoriesRequest = request_element
        else
          raise ArgumentError, "Invalid group type"
        end

        group
      end
    end
  end
end