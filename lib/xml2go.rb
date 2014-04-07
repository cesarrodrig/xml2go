require "nokogiri"
require "optparse"


module Xml2Go

  SUPPORTED_TYPES = ["bool",  "int", "float64", "string"]
  INVALID_CHARS = ["-"]

  # ruby's .capitalize ignores Camel case
  def self.cap(s)
    s[0] = s[0].upcase
    return s
  end

  # remove invalid chars, capitalize and camelcase it
  def self.normalize(s)
    s = cap(s)
    INVALID_CHARS.each do |char|
      s.gsub!(char, "_")
    end

    return s.gsub(/(?<=_|^)(\w)/){$1.upcase}.gsub(/(?:_)(\w)/,'\1')
  end

  def self.numeric?(str)
    Float(str) != nil rescue false
  end

  # take 's' out of string and return if it was plural or not
  def self.singularize(string)
    return [string, false]
    if string[-1] == "s" then
        string = string[0..-2]
        return [string, true]
    end
  end

  # class representing a Go struct
  class Struct
    attr_accessor :properties, :name

    # represents member variables
    class Property
      attr_accessor :type, :name, :xml_tag

      def initialize(name, type, xml_tag)
        @name = name
        @type = type
        @xml_tag = xml_tag
      end

      def to_s
        "#{@name} #{@type} `xml:\"#{@xml_tag}\"`"
      end

    end

    def initialize(name)
      # @name, _ = Xml2Go::singularize(name)
      @name = name
      @properties = {}
    end

    # adds member variable to struct
    def add_property(var_name, type, xml_tag)
      # struct already has that property, consider it an array
      if @properties.has_key?(var_name) && !@properties[var_name].type.include?("[]") then
        @properties[var_name].type = "[]" + @properties[var_name].type

        if Xml2Go::config[:plural_arrays] then
          @properties[var_name].name << "s" if @properties[var_name].name[-1] != "s"
        end

      else
        @properties[var_name] = Property.new(var_name, type, xml_tag)
      end
    end

    def to_s
      properties_string = properties.values.join("\n")
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
  end

  def self.get_struct_member(element)
    type = normalize(element.name)
    var_name = type
    xml_tag = element.name
    [var_name, type, xml_tag]
  end

  # adds the XML attrs of element to the Go struct
  def self.add_attrs_to_struct(element, struct)
    if element.respond_to?(:attributes) then
      element.attributes.each do |attri, value|
        var_name = attri.dup
        struct.add_property(normalize(var_name), get_type(value.text), "#{attri},attr")
      end
    end
  end

  # Add XML node, which contains more child nodes, as a member struct
  def self.add_xml_node(element, struct)
    var_name, type, xml_tag = get_struct_member(element)

    type, plural = Xml2Go::singularize(type)
    type = "[]" + type if plural

    begin
      xml_tag = element.namespace.prefix << ":" << xml_tag
    rescue => e
       # :)
    end

    struct.add_property(var_name, type, xml_tag)
  end

  # Add XML node, which contains no child nodes, as a primitive type
  # if it contains attrs, add it as a struct.
  def self.add_xml_primitive(element, struct)
    var_name, type, xml_tag = get_struct_member(element)

    # is this a primitive with attrs?
    prim_attrs = element.attributes.select{ |k,v| !k.include?("type") }
    if prim_attrs.length > 0 then

      struct.add_property(var_name, type, xml_tag)
      parse_element(element)
    else

      type = get_type_from_elem(element)
      struct.add_property(var_name, type, xml_tag)
    end
  end

  def self.parse_element(element)
    struct_name = normalize(element.name)
    # TODO cesar: maybe we DO want to process repeated structs
    # to capture arrays don't process to structs
    return if @@structs.has_key?(struct_name)

    struct = Struct.new(struct_name)

    # add attributes as properties
    if @@config[:add_attrs] then
      add_attrs_to_struct(element, struct)
    end

    element.elements.each do |child|
      # this is a struct
      if child.elements.count > 0 then
        add_xml_node(child, struct)
        parse_element(child)

      else # this is an XML primitive
        add_xml_primitive(child, struct)
      end
    end

    @@structs[struct.name] = struct
  end

  # analyses the xml element to try and fetch the type
  # if can't figure it out, returns 'string'
  def self.get_type_from_elem(element)

    if @@config[:detect_type] then
      # check and see if the type is provided in the attributes
      element.attributes.each do |k,v|
        if k.include?("type") then
          type = v.value.split(":").last
          return type if SUPPORTED_TYPES.include?(type)
        end
      end
    end

    return get_type(element.child.to_s)
  end

  def self.get_type(string)
    # try to figure out the type
    if numeric?(string) then
      return "float64" if Float(string).to_s.length == string.length
      return "int"
    end
    return "bool" if ["true", "false"].include?(string)
    return "string"
  end

  def self.write_to_file(filename)
    file_handle = File.new(filename, "w")
    file_handle.write("package main\n\n")
    file_handle.write(@@structs.values.join("\n"))
    file_handle.close()
  end

  def self.parse_options(args)
    @@config = {}
    optparse = OptionParser.new do|opts|
      opts.banner = "Usage: xml2go [options] <input_xml_file> <output_file>"

      opts.on("-a", "--add-attrs", "Add XML attributes as part of the struct") do |a|
        @@config[:add_attrs] = true
      end

      opts.on("-p", "--plural-arrays", "Pluralize array names") do |p|
        @@config[:plural_arrays] = true
      end

      opts.on("-t", "--detect-type",
          "Attempt to detect the type of a primitive by searching in the attrs") do |p|
        @@config[:detect_type] = true
      end

    end
    optparse.parse!(args)
  end

  def self.config
    @@config
  end

end
