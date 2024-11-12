class Result
  ATTRIBUTES = %i[command mean stddev median user system min max times commit].freeze
  attr_accessor(*ATTRIBUTES)

  def initialize(attributes = {})
    attributes.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end

    self.commit = attributes.dig("parameters", "commit")
  end

  def inspect
    inspected_values = ATTRIBUTES.map { |attr| "#{attr}: #{send(attr).inspect}" }.join(", ")
    "#<#{self.class} #{inspected_values}>"
  end

  def self.from_json(path)
    raise ArgumentError, "Path must be a string" unless path.is_a?(String)

    file = File.read(path)
    JSON.parse(file)
    #parsed = JSON.parse(file)
    #parsed["results"].map do |hash|
    #  Result.new(hash)
    #end
  rescue JSON::ParserError => e
    puts "Failed to parse JSON: #{e.message}"
  rescue Errno::ENOENT => e
    puts "File not found: #{e.message}"
  end
end
