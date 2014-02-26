require "nokogiri"

"""

To run:
  bundle exec ruby xml2go.rb <xml_file> <go_output_file>

"""

class String
  def numeric?
    Float(self) != nil rescue false
  end
end

module Xml2Go

  SUPPORTED_TYPES = ["bool",  "int", "float64", "string"]

  # .capitalize ignores Camel case
  def self.cap(s)
    s[0] = s[0].upcase
    return s
  end

  def self.singularize(s)
    if s[-1] == "s" then
        s = s[0..-2]
        return [s, true]
    end
    return [s, false]
  end

  class Struct
    attr_accessor :properties, :name

    def initialize(name)

      @name, _ = Xml2Go::singularize(name)
      # array strings
      @properties = Set.new
    end

    def to_s
      properties_string = properties.to_a.join("\n")
      "type #{@name} struct {\n
      #{properties_string}
      }
      "
    end

  end

  def self.load(file_handle)
    @@doc = Nokogiri::XML(file_handle)
    @@structs = {}
  end

  def self.parse
    parse_element(@@doc)
    return @@structs
  end

  def self.parse_element(element)
    struct_name = cap(element.name)
    return if @@structs.has_key?(struct_name)
    
    struct = Struct.new(struct_name)
    element.elements.each do |child|
      type = cap(child.name)
      var_name = type
      xml_tag = child.name
      # this is a struct
      if child.elements.count > 0 then
        type, plural = singularize(type)
        type = "[]" + type if plural

        begin
          xml_tag = child.namespace.prefix << ":" << xml_tag
        rescue => e
           #:)
        end 
        
        struct.properties << "#{var_name} #{type} `xml:\"#{xml_tag}\"`"
        parse_element(child)
      
      else # this is a primitive
        type = get_type(child)
        struct.properties << "#{var_name} #{type} `xml:\"#{xml_tag}\"`"
      end
    end
    
    @@structs[struct.name] = struct 
  end


  def self.get_type(element)
    
    # check and see if the type is provided in the attributes
    element.attributes.each do |k,v|
      if k.include?("type") then
        type = v.value.split(":").last
        return type if SUPPORTED_TYPES.include?(type) 
      end
    end
    
    s = element.child.to_s 
    if s.numeric? then
      return "float64" if Float(s).to_s.length == s.length
      return "int"
    end
    return "bool" if ["true", "false"].include?(s)
    return "string"

  end


end

# pass file as argument
Xml2Go::load(File.open(ARGV[0], "r"))
structs_results = Xml2Go::parse.values.join("\n")
file_handle = File.new(ARGV[1], "w")
file_handle.write("package main\n\n")
file_handle.write(structs_results)
file_handle.close()
v = `gofmt -w --tabs=false --tabwidth=4 #{ARGV[1]}`