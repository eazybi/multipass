require 'time'
require 'ezcrypto'

class MultiPass
  class Invalid < StandardError
    class << self
      attr_accessor :message
    end
    self.message = "The MultiPass token is invalid."

    attr_reader :data, :json, :options

    def initialize(data = nil, json = nil, options = nil)
      @data    = data
      @json    = json
      @options = options
    end

    def message
      self.class.message
    end

    alias to_s message
  end

  class ExpiredError < Invalid
    self.message = "The MultiPass token has expired."
  end
  class JSONError < Invalid
    self.message = "The decrypted MultiPass token is not valid JSON."
  end
  class DecryptError < Invalid
    self.message = "The MultiPass token was not able to be decrypted."
  end

  def self.encode(site_key, api_key, options = {})
    new(site_key, api_key).encode(options)
  end

  def self.decode(site_key, api_key, data)
    new(site_key, api_key).decode(data)
  end

  # options:
  #   :url_safe => true
  def initialize(site_key, api_key, options = {})
    @site_key   = site_key
    @api_key    = api_key
    @url_safe   = !options.key?(:url_safe) || options[:url_safe]
    @crypto_key = EzCrypto::Key.with_password(@site_key, @api_key)
  end

  def url_safe?
    !!@url_safe
  end

  # Encrypts the given hash into a multipass string.
  def encode(options = {})
    options[:expires] = case options[:expires]
      when Fixnum               then Time.at(options[:expires]).to_s
      when Time, DateTime, Date then options[:expires].to_s
      else options[:expires].to_s
    end
    self.class.encode_64 @crypto_key.encrypt(options.to_json), @url_safe
  end

  # Decrypts the given multipass string and parses it as JSON.  Then, it checks
  # for a valid expiration date.
  def decode(data)
    json = options = nil
    json = @crypto_key.decrypt(self.class.decode_64(data, @url_safe))
    
    if json.nil?
      raise MultiPass::DecryptError.new(data)
    end

    options = decode_json(data, json)
    
    if !options.is_a?(Hash)
      raise MultiPass::JSONError.new(data, json, options)
    end

    options.keys.each do |key|
      options[key.to_sym] = options.delete(key)
    end

    if options[:expires].nil? || Time.now.utc > Time.parse(options[:expires])
      raise MultiPass::ExpiredError.new(data, json, options)
    end

    options
  rescue CipherError
    raise MultiPass::DecryptError.new(data, json, options)
  end

  CipherError = OpenSSL.const_defined?(:CipherError) ? OpenSSL::CipherError : OpenSSL::Cipher::CipherError

  if Object.const_defined?(:ActiveSupport)
    include ActiveSupport::Base64
  else
    require 'base64'
  end

  def self.encode_64(s, url_safe = true)
    b = Base64.encode64(s)
    b.gsub! /\n/, ''
    if url_safe
      b.tr! '+', '-'
      b.tr! '/', '_'
    end
    b
  end

  def self.decode_64(s, url_safe = true)
    if url_safe
      s = s.dup
      s.tr! '-', '+'
      s.tr! '_', '/'
    end
    Base64.decode64(s)
  end

  if Object.const_defined?(:ActiveSupport)
    def decode_json(data, s)
      ActiveSupport::JSON.decode(s)
    rescue ActiveSupport::JSON::ParseError
      raise MultiPass::JSONError.new(data, s)
    end
  else
    require 'json'
    def decode_json(data, s)
      JSON.parse(s)
    rescue JSON::ParserError
      raise MultiPass::JSONError.new(data, s)
    end
  end
end