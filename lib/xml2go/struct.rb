
module Xml2Go

  # class representing a Go struct
  class Struct
    attr_accessor :fields, :name

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
      @fields = {}
    end

    # adds member variable to struct
    def add_property(var_name, type, xml_tag)
      # struct already has that property, consider it an array
      if @fields.has_key?(var_name) && !@fields[var_name].type.include?("[]") then
        @fields[var_name].type = "[]" + @fields[var_name].type

        if Xml2Go::config[:plural_arrays] then
          @fields[var_name].name << "s" if @fields[var_name].name[-1] != "s"
        end

      else
        @fields[var_name] = Property.new(var_name, type, xml_tag)
      end
    end

    def to_s
      fields_string = fields.values.join("\n")
      "type #{@name} struct {\n
        #{fields_string}
      }"
    end

  end
end