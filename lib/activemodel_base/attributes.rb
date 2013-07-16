require 'uuid'

module ActiveModel

  module Attributes
    
    def self.included(base)
      base.class_inheritable_hash :model_attributes
      base.model_attributes = HashWithIndifferentAccess.new
      base.extend ClassMethods
      base.attribute :id
    end

    # Convert a value to a specified type in a consistent manner.
    # If type is given as nil, no conversion will be applied.
    # If an unknown type is specified, the method to_#{type} will be called on value.
    # If an error is raised during conversion, nil will be returned.
    def self.convert_to(type, value)
      begin
        case type
        when :integer
          value.to_i
        when :float
          value.to_f
        when :string
          value.to_s
        when :date
          value.respond_to?(:to_date) ? value.to_date : Date.parse(value.to_s)
        when :datetime
          value.respond_to?(:to_datetime) ? value.to_datetime : DateTime.parse(value.to_s)
        when nil
          value
        else
          value.send("to_#{type}".to_sym)
        end
      rescue
        nil
      end
    end

    include Comparable

    def initialize(new_attributes={})
      new_attributes.each { |name, value| send("#{name}=",value) }
      super()
    end

    # If you need to compare against something more than just the attributes then override this.
    def <=>(other)
      (attributes.keys - [:id]).map(&:to_s).sort.map(&:to_sym).inject(attributes[:id] <=> other.attributes[:id]) do |rc, key|
        if rc == 0
          attributes[key] <=> other.attributes[key] rescue 0
        else
          rc
        end
      end
    end

    def attributes(keys=[])
      @attributes ||= HashWithIndifferentAccess.new
      keys.blank? ? @attributes : keys.map(&:to_sym).inject(HashWithIndifferentAccess.new) { |hash, key| hash[key] = @attributes[key]; hash }
    end

    def persisted?
      false
    end

    def read_attribute(key)
      attributes[key.to_sym]
    end

    def read_attribute_for_validation(key)
      attributes[key]
    end

    private

    def write_attribute(key, value)
      key = key.to_sym
      type = (self.model_attributes[key] || {})[:type]
      attributes[key] = ActiveModel::Attributes.convert_to(type, value)
    end

    def calculated_id
      id_related_attributes = id_attributes
      unless id_related_attributes.blank?
        attributes(id_related_attributes).to_a.map { |x| x.map(&:to_s) }.sort { |a, b| a.first <=> b.first }.map(&:last).join("_")
      else
        read_attribute(:id) || UUID.new.generate.gsub("-","").to_i(16)
      end
    end

    def id_attributes
      model_attributes.keys.select { |attribute_name| id_attribute?(attribute_name) }
    end

    def id_attribute?(attr)
      attr = attr.to_sym
      has_attribute?(attr) && model_attributes[attr][:id]
    end

    def has_attribute?(attr)
      model_attributes.has_key?(attr)
    end

    module ClassMethods

      def attribute(*names)
        options = names.extract_options!

        options[:id] = false unless options.has_key?(:id)
        options[:readonly] = false unless options.has_key?(:readonly)
        options[:allow_nil] = true unless options.has_key?(:allow_nil)

        names.each do |attribute_name|

          def_command = "def #{attribute_name}"
          model_attributes_command = "self.model_attributes[:#{attribute_name}] = #{options.inspect}"
          reader_command = "read_attribute(:#{attribute_name})"
          visibility_command = "public(:#{attribute_name})"

          class_eval(<<-EOS_ATTRIBUTE_READ, __FILE__, __LINE__ + 1)
           #{model_attributes_command}
           #{def_command}
              #{reader_command}
            end
            #{visibility_command}
          EOS_ATTRIBUTE_READ

          # We will always create the method so that it can be used internally if needed. It will just been hidden from the public if it should appear non existent.
          def_command = "def #{attribute_name}=(new_value)"
          writer_command = "write_attribute(:#{attribute_name}, new_value)"
          visibility = options[:readonly] ? 'private' : 'public'
          visibility_command = "#{visibility}(:#{attribute_name}=)"
          class_eval(<<-EOS_ATTRIBUTE_WRITE, __FILE__, __LINE__ + 1)
            #{def_command}
              #{writer_command}
            end
            #{visibility_command}
          EOS_ATTRIBUTE_WRITE
        end
      end

      alias :attributes :attribute

    end

  end

end
