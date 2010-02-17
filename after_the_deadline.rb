require 'crack'
require 'net/http'
require 'uri'

class AfterTheDeadline
  attr_accessor :api_key
  
  BASE_URI = 'http://service.afterthedeadline.com'
  
  def initialize(key = nil)
    self.api_key = key
  end
  
  # Invoke checkDocument service with provided text and optional key.
  # If no key is provided, a default key is used.
  # 
  # Returns list of AfterTheDeadline::Error objects.
  def check(data, key = nil)
    results = Crack::XML.parse(perform('/checkDocument', :key => key, :data => data))['results']
    return [] if results.nil? # we have no errors in our data
    
    raise "Server returned an error: #{results['message']}" if results['message']
    if results['error'].kind_of?(Array)
      return results['error'].map { |e| AfterTheDeadline::Error.new(e) }
    else
      return [AfterTheDeadline::Error.new(results['error'])]
    end
  end
  alias :check_document :check
  
  # Invoke stats service with provided text and optional key.
  # If no key is provided, a default key is used.
  # 
  # Returns AfterTheDeadline::Metrics object.
  def metrics(data, key = nil)
    results = Crack::XML.parse(perform('/stats', :key => key, :data => data))['scores']
    return if results.nil? # we have no stats about our data
    AfterTheDeadline::Metrics.new results['metric']
  end
  alias :stats :metrics
  
  # Invoke the verify service with optional key.
  # If no key is provided, a default key is used.
  # 
  # Returns boolean indicating validity of key.
  def verify(key = nil)
    'valid' == perform('/verify', :key => key).strip
  end
  
private
  def perform(action, params)
    params[:key] ||= self.api_key
    raise 'Please provide key as argument or set the api_key attribute first' unless params[:key]
    response = Net::HTTP.post_form URI.parse(BASE_URI + action), params
    raise "Unexpected response code from AtD service: #{response.code} #{response.message}" unless response.is_a? Net::HTTPSuccess
    response.body
  end
end

class AfterTheDeadline::Error
  attr_reader :string, :description, :precontext, :type, :suggestions, :url
  
  def initialize(hash)
    raise "#{self.class} must be initialized with a Hash" unless hash.kind_of?(Hash)
    [:string, :description, :precontext, :type, :url].each do |attribute|
      self.send("#{attribute}=", hash[attribute.to_s])
    end
    self.suggestions = hash['suggestions'].nil? ? [] : [*hash['suggestions']['option']]
  end
  
  def info(theme = nil)
    return unless self.url
    uri = URI.parse self.url
    uri.query = (uri.query || '') + "&theme=#{theme}"
    Net::HTTP.get(uri).strip
  end
  
  def to_s
    "#{self.string} (#{self.description})"
  end
  
private
  attr_writer :string, :description, :precontext, :type, :suggestions, :url
end

class AfterTheDeadline::Metrics
  attr_reader :spell, :grammer, :stats, :style
  
  def initialize(array)
    unless array.kind_of?(Array) && array.all? {|i| i.kind_of?(Hash) }
      raise "#{self.class} must be initialized with an Array of Hashes"
    end
    
    self.spell, self.grammer, self.stats, self.style = {}, {}, {}, {}
    array.each do |metric|
      self.send(metric['type'])[metric['key']] = metric['value']
    end
  end
  
private
  attr_writer :spell, :grammer, :stats, :style
end
