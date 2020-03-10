# frozen_string_literal: true

require 'faraday_adapter_socks'

module Bitfinex
  ###
  # Base REST API client methods
  ###
  module RESTClient
    def check_params(params, allowed_params)
      raise ParamsError unless if (params.keys - allowed_params).empty? # rubocop:disable Style/GuardClause
                                 params
                               else
                                 raise ParamsError
                               end
    end

    private

    def get(url, params = {})
      rest_connection.get do |req|
        req.url build_url(url)
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json'

        params.each do |k, v|
          req.params[k] = v
        end

        req.options.timeout = config[:rest_timeout]
        req.options.open_timeout = config[:rest_open_timeout]
      end
    end

    def rest_connection
      @conn ||= new_rest_connection # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def build_url(url)
      URI.join(base_api_endpoint, url)
    end

    def new_rest_connection
      Faraday.new(url: base_api_endpoint, proxy: config[:proxy]) do |conn|
        conn.use Bitfinex::CustomErrors
        if config[:debug_connection]
          conn.response :logger, Logger.new(STDOUT), bodies: true
        end
        conn.use FaradayMiddleware::ParseJson, content_type: /\bjson$/
        conn.adapter :net_http_socks
      end
    end

    def base_api_endpoint
      config[:api_endpoint]
    end

    def authenticated_post(url, options = {}) # rubocop:disable all
      raise Bitfinex::InvalidAuthKeyError unless valid_key?

      complete_url = build_url(url)
      body = options[:params] || {}
      nonce = new_nonce

      payload = if config[:api_version] == 1
                  build_payload("/v1/#{url}", options[:params], nonce)
                else
                  "/api/v2/#{url}#{nonce}#{body.to_json}"
                end

      rest_connection.post do |req|
        req.url complete_url
        req.body = body.to_json
        req.options.timeout = config[:rest_timeout]
        req.options.open_timeout = config[:rest_open_timeout]
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json'

        if config[:api_version] == 1
          req.headers['X-BFX-PAYLOAD'] = payload
          req.headers['X-BFX-SIGNATURE'] = sign(payload)
          req.headers['X-BFX-APIKEY'] = config[:api_key]
        else
          req.headers['bfx-nonce'] = nonce
          req.headers['bfx-signature'] = sign(payload)
          req.headers['bfx-apikey'] = config[:api_key]
        end
      end
    end

    def build_payload(url, params, nonce)
      payload = {}
      payload['nonce'] = nonce
      payload['request'] = url
      payload.merge!(params) if params
      Base64.strict_encode64(payload.to_json)
    end

    def new_nonce
      (Time.now.to_f * 1000).floor.to_s
    end

    def sign(payload)
      OpenSSL::HMAC.hexdigest('sha384', config[:api_secret], payload)
    end

    def valid_key?
      !(config[:api_key] && config[:api_secret]).nil?
    end
  end
end
