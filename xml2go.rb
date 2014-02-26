require "nokogiri"

module Xml2Go

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
    struct = Struct.new(struct_name)

    element.elements.each do |child|
      type = cap(child.name)
      var_name = type
      
      # this is a struct
      if child.elements.count > 0 then
        type, plural = singularize(type)
        type = "[]" + type if plural
        struct.properties << "#{var_name} #{type} `xml:\"#{child.name}\"`"
        parse_element(child)
      
      else # this is a primitive

        # only useful for vindicia xmls =D
        type = child["xsi:type"].split(":").last if child["xsi:type"]
        struct.properties << "#{var_name} #{type} `xml:\"#{child.name}\"`"
      end
    end
    
    @@structs[struct.name] = struct if !@@structs.has_key?(struct.name)
  end


end

# pass file as argument
Xml2Go::load(File.open(ARGV[0], "r"))
structs_results = Xml2Go::parse.values.join("\n")
file_handle = File.new("structs.go", "w")
file_handle.write("package acajoe\n\n")
file_handle.write(structs_results)