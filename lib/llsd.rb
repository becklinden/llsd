require 'rexml/document'
require 'date'

# Class for parsing and generating llsd xml
class LLSD
  class SerializationError < StandardError; end

  LLSD_ELEMENT = 'llsd'

  BOOLEAN_ELEMENT = 'boolean'
  INTEGER_ELEMENT = 'integer'
  REAL_ELEMENT = 'real'
  UUID_ELEMENT = 'uuid'
  STRING_ELEMENT = 'string'
  BINARY_ELEMENT = 'binary'
  DATE_ELEMENT = 'date'
  URI_ELEMENT = 'uri'
  KEY_ELEMENT = 'key'
  UNDEF_ELEMENT = 'undef'

  ARRAY_ELEMENT = 'array'
  MAP_ELEMENT = 'map'

  # PARSING AND ENCODING FUNCTIONS

  def self.to_xml(obj)
    llsd_element = REXML::Element.new LLSD_ELEMENT
    llsd_element.add_element(serialize_ruby_obj(obj))

    doc = REXML::Document.new
    doc << llsd_element
    doc.to_s
  end

  def self.parse(xml_string)
    # turn message into dom element
    doc = REXML::Document.new xml_string

    # get the first element inside the llsd element
    # if there is more than one element then return nil

    # return parse dom element on first element
    parse_dom_element doc.root.elements[1]
  end

  private

  def self.serialize_ruby_obj(obj)
    # if its a container (hash or map)

    case obj
    when Hash
      map_element = REXML::Element.new(MAP_ELEMENT)
      obj.each do |key, value|
        key_element = REXML::Element.new(KEY_ELEMENT)
        key_element.text = key.to_s
        value_element = serialize_ruby_obj value

        map_element.add_element key_element
        map_element.add_element value_element
      end

      map_element

    when Array
      array_element = REXML::Element.new(ARRAY_ELEMENT)
      obj.each { |o| array_element.add_element(serialize_ruby_obj(o)) }
      array_element

    when Fixnum, Integer
      integer_element = REXML::Element.new(INTEGER_ELEMENT)
      integer_element.text = obj.to_s
      integer_element

    when TrueClass, FalseClass
      boolean_element = REXML::Element.new(BOOLEAN_ELEMENT)

      if obj
        boolean_element.text = 'true'
      else
        boolean_element.text = 'false'
      end

      boolean_element

    when Float
      real_element = REXML::Element.new(REAL_ELEMENT)
      real_element.text = obj.to_s
      real_element

    when Date
      date_element = REXML::Element.new(DATE_ELEMENT)
      date_element.text = obj.new_offset(of=0).strftime('%Y-%m-%dT%H:%M:%SZ')
      date_element

    when String
      if !obj.empty?
        string_element = REXML::Element.new(STRING_ELEMENT)
        string_element.text = obj.to_s
        string_element
      else
        STRING_ELEMENT
      end

    when NilClass
      UNDEF_ELEMENT

    else
      raise SerializationError, "#{obj.class.to_s} class cannot be serialized into llsd xml - please serialize into a string first"
    end
  end

  def self.parse_dom_element(element)
    # pseudocode:

    #   if it is a container
    #     if its an array
    #       collect parse_dom_element applied to each child into an array
    #     else (its a map)
    #       collect parse_dom_element applied to each child into an hash
    #   else (its an atomic element)
    #     then extract the value to a native type
    #
    #   return the value

    case element.name
    when ARRAY_ELEMENT
      element_value = []
      element.elements.each {|child| element_value << (parse_dom_element child) }

    when MAP_ELEMENT
      element_value = {}
      element.elements.each do |child|
        if child.name == 'key'
          element_value[child.text] = parse_dom_element child.next_element
        end
      end

    else
      element_value = convert_to_native_type(element.name, element.text, element.attributes)
    end

    element_value
  end

  def self.convert_to_native_type(element_type, unconverted_value, attributes)
    case element_type
    when INTEGER_ELEMENT
      unconverted_value.to_i

    when REAL_ELEMENT
      unconverted_value.to_f

    when BOOLEAN_ELEMENT
      if unconverted_value == 'false' or unconverted_value.nil? # <boolean />
        false
      else
        true
      end

    when STRING_ELEMENT
      if unconverted_value.nil? # <string />
        ''
      else
        unconverted_value
      end

    when DATE_ELEMENT
      if unconverted_value.nil?
        DateTime.strptime('1970-01-01T00:00:00Z')
      else
        DateTime.strptime(unconverted_value)
      end

    when UUID_ELEMENT
      if unconverted_value.nil?
        '00000000-0000-0000-0000-000000000000'
      else
        unconverted_value
      end

    else
      unconverted_value
    end
  end
end
