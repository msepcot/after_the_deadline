require 'crack'
require 'net/http'
require 'uri'

def AfterTheDeadline(dictionary = nil, types = AfterTheDeadline::DEFAULT_IGNORE_TYPES)
  AfterTheDeadline.set_custom_dictionary(dictionary)
  AfterTheDeadline.set_ignore_types(types)
  nil
end

class AfterTheDeadline
  @@custom_dictionary = []
  @@ignore_types = []
  @@api_key = nil

  BASE_URI = 'http://service.afterthedeadline.com'
  DEFAULT_IGNORE_TYPES = ['Bias Language', 'Cliches', 'Complex Expression', 'Diacritical Marks', 'Double Negatives', 'Hidden Verbs', 'Jargon Language', 'Passive voice', 'Phrases to Avoid', 'Redundant Expression']

  class <<self
    def set_custom_dictionary(dict)
      if dict.kind_of?(Array)
        @@custom_dictionary = dict
      elsif dict.kind_of?(String)
        File.open(dict) { |f| @@custom_dictionary = f.readlines.map &:strip }
      end
    end

    def set_ignore_types(types)
      @@ignore_types = types if types.kind_of?(Array)
    end

    def set_api_key(key)
      @@api_key = key
    end

    # Invoke the checkDocument service with provided text.
    #
    # Returns list of AfterTheDeadline::Error objects.
    def check(data)
      results = Crack::XML.parse(perform('/checkDocument', :data => data))['results']
      return [] if results.nil? # we have no errors in our data

      raise "Server returned an error: #{results['message']}" if results['message']
      errors = if results['error'].kind_of?(Array)
        results['error'].map { |e| AfterTheDeadline::Error.new(e) }
      else
        [AfterTheDeadline::Error.new(results['error'])]
      end

      # Remove any error types we don't care about
      errors.reject! { |e| @@ignore_types.include?(e.description) }

      # Remove spelling errors from our custom dictionary
      errors.reject! { |e| e.type == 'spelling' && @@custom_dictionary.include?(e.string) }
      return errors
    end
    alias :check_document :check

    # Invoke the stats service with provided text.
    #
    # Returns AfterTheDeadline::Metrics object.
    def metrics(data)
      results = Crack::XML.parse(perform('/stats', :data => data))['scores']
      return if results.nil? # we have no stats about our data
      AfterTheDeadline::Metrics.new results['metric']
    end
    alias :stats :metrics

    def perform(action, params)
      params[:key] = @@api_key if @@api_key
      response = Net::HTTP.post_form URI.parse(BASE_URI + action), params
      raise "Unexpected response code from AtD service: #{response.code} #{response.message}" unless response.is_a? Net::HTTPSuccess
      response.body
    end
  end

  private_class_method :perform
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

  def eql?(other)
    self.class.equal?(other.class) &&
      string == other.string &&
      description == other.description &&
      type == other.type
  end
  alias_method :==, :eql?

  def hash
    string.hash ^ description.hash ^ type.hash
  end

private
  attr_writer :string, :description, :precontext, :type, :suggestions, :url
end

class AfterTheDeadline::Metrics
  attr_reader :spell, :grammar, :stats, :style

  def initialize(array)
    unless array.kind_of?(Array) && array.all? {|i| i.kind_of?(Hash) }
      raise "#{self.class} must be initialized with an Array of Hashes"
    end

    self.spell, self.grammar, self.stats, self.style = {}, {}, {}, {}
    array.each do |metric|
      self.send(metric['type'])[metric['key']] = metric['value']
    end
  end

private
  attr_writer :spell, :grammar, :stats, :style
end
