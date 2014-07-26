
module Xml2Go

  # represents member variables
  class Field
    attr_accessor :type, :name, :xml_tag, :value

    def initialize(name, type, xml_tag, value)
      @name = name
      @type = type
      @xml_tag = xml_tag
      @value = value
      @const_name = Xml2Go::get_const_name(@name)
    end

    def to_s
      "#{@name} #{@type} `xml:\"#{@xml_tag}\"`"
    end

    def to_declaration
      value = @value.nil? ? Xml2Go::low(@name) : @const_name
      "#{@name}: #{value},"
    end

    def to_const
      if !value.nil? then
        return "#{@const_name} = \"#{@value}\""
      end
      return ""
    end

  end # class Field

  # class representing a Go struct
  class Struct
    attr_accessor :fields, :type

    def initialize(type)
      @type = type
      @fields = {}
    end

    # adds member variable to struct
    def add_field(var_name, type, xml_tag, value=nil)
      @fields[var_name] = Field.new(var_name, type, xml_tag, value)
    end

    # adds member variable to struct
    def delete_field(var_name)
      @fields.delete(var_name)
    end

    def to_s
      fields_string = @fields.values.join("\n")
      "type #{@type} struct {\n
      #{fields_string}
      }
      "
    end

    def to_declaration
      fields_string = @fields.values.map { |v| v.to_declaration}
      "#{Xml2Go::low(@type)} := #{@type} {
      #{fields_string.join("\n")}
      }"
    end

    def get_consts
      consts_string = @fields.values.map{ |v| v.to_const}
      "// #{@type} info \n" << consts_string.join("\n")
    end

  end


end