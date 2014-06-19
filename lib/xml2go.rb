require "nokogiri"
require "optparse"

require 'xml2go/struct'
require 'xml2go/parser'

module Xml2Go

  def self.get_const_name(str)
    final_str = ""
    return str.gsub(/([A-Z])/){|c| "_#{c}"}.gsub(/^_/, "").upcase
  end

  def self.load(file_handle)
    @@doc = Nokogiri::XML(file_handle)
    @@structs = {}
  end

  def self.parse(config)
    @@config = config
    parse_element(@@doc)
  end

  def self.parse_element(element)
    @@parser = Xml2Go::Parser.new(@@config)
    @@parser.parse_element(element)
    @@structs = @@parser.structs
    return
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

  def self.write_mocks_to_file(filename)
    file_handle = File.new(filename, "w")
    file_handle.write("package main\n\n")
    consts = @@structs.values.map{ |v| v.get_consts }
    file_handle.write(consts.join("\n"))
    blobs = @@structs.values.map { |v| v.to_declaration}
    file_handle.write(blobs.join("\n"))
    file_handle.close()
  end

end
