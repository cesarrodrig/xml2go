
module Xml2Go

  class Parser

    SUPPORTED_TYPES = ["bool",  "int", "float64", "string"]
    INVALID_CHARS = ["-"]

    attr_reader :structs

    def initialize(config)
      @config = config
      @structs = {}
    end

    # ruby's .capitalize ignores Camel case
    def cap(s)
      s[0] = s[0].upcase
      return s
    end


    # ruby's .capitalize ignores Camel case
    def low(s)
      dup = s.dup
      dup[0] = dup[0].downcase
      return dup
    end


    # remove invalid chars, capitalize and camelcase it
    def normalize(s)
      s = cap(s)
      INVALID_CHARS.each do |char|
        s.gsub!(char, "_")
      end

      return s.gsub(/(?<=_|^)(\w)/){$1.upcase}.gsub(/(?:_)(\w)/,'\1')
    end

    def numeric?(str)
      Float(str) != nil rescue false
    end

    # take 's' out of string and return if it was plural or not
    def singularize(string)
      if string[-1] == "s" then
          s = string[0..-2]
          return [s, true]
      end
      return [string, false]
    end

    def get_struct_member(element)
      type = normalize(element.name)
      var_name = type
      xml_tag = element.name
      [var_name, type, xml_tag]
    end

    def add_field_to_struct(struct, var_name, type, xml_tag)
      if struct.fields.has_key?(var_name) &&
          !struct.fields[var_name].type.include?("[]") then

        type, sing = singularize(struct.fields[var_name].type)

        struct.fields[var_name].type = "[]" + type

        if @config[:plural_arrays] then
          struct.fields[var_name].name << "s" if struct.fields[var_name].name[-1] != "s"
        end

      else
        struct.add_field(var_name, type, xml_tag)
      end
    end

    # adds the XML attrs of element to the Go struct
    def add_attrs_to_struct(element, struct)
      if element.respond_to?(:attributes) then
        element.attributes.each do |attri, value|
          var_name = attri.dup
          add_field_to_struct(struct, normalize(var_name), get_type(value.text), "#{attri},attr")
        end
      end
    end

    # Add XML node, which contains more child nodes, as a member struct
    def add_xml_node(element, struct)
      var_name, type, xml_tag = get_struct_member(element)

      type, plural = singularize(type)
      type = "[]" + type if plural

      begin
        xml_tag = element.namespace.prefix << ":" << xml_tag
      rescue => e
         # :)
      end

      add_field_to_struct(struct, var_name, type, xml_tag)
    end

    # Add XML node, which contains no child nodes, as a primitive type
    # if it contains attrs, add it as a struct.
    def add_xml_primitive(element, struct)
      var_name, type, xml_tag = get_struct_member(element)

      # is this a primitive with attrs?
      prim_attrs = element.attributes.select{ |k,v| !k.include?("type") }
      if prim_attrs.length > 0 then

        add_field_to_struct(struct, var_name, type, xml_tag)
        parse_element(element)
      else

        type = get_type_from_elem(element)
        add_field_to_struct(struct, var_name, type, xml_tag)
      end
    end

    def parse_element(element)
      struct_name = normalize(element.name)
      # TODO: maybe we DO want to process repeated structs
      # to capture arrays don't process to structs
      return if @structs.has_key?(struct_name)

      struct = Xml2Go::Struct.new(struct_name)

      # add attributes as properties
      if @config[:add_attrs] then
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

      @structs[struct.type] = struct
    end

    # analyses the xml element to try and fetch the type
    # if can't figure it out, returns 'string'
    def get_type_from_elem(element)

      if @config[:detect_type] then
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

    def get_type(string)
      # try to figure out the type
      if numeric?(string) then
        return "float64" if Float(string).to_s.length == string.length
        return "int"
      end
      return "bool" if ["true", "false"].include?(string)
      return "string"
    end

  end


end