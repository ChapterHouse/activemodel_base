module ActiveModel

  module Attributes
    
    def self.included(base)
      base.class_inheritable_hash :model_attributes
      base.model_attributes = HashWithIndifferentAccess.new
      base.extend ClassMethods
      base.attribute :id
    end

    include Comparable

    def initialize(new_attributes={})
      new_attributes.each { |name, value| send("#{name}=",value) }
#      self.id = calculated_id unless attributes.has_key?(:id) || !respond_to?(:calculated_id)
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

    def read_attribute_for_validation(key)
      attributes[key]
    end

    def save
      if valid?
        model_attributes.each do |name, options|
          case options[:type]
          when :integer
            attributes[name] = attributes[name].to_i
          when :float
            attributes[name] = attributes[name].to_f
          when :string
            attributes[name] = attributes[name].to_s
          when :date
            attributes[name] = attributes[name].respond_to?(:to_date) ? attributes[name].to_date : Date.parse(attributes[name].to_s)
          when :datetime
            attributes[name] = attributes[name].respond_to?(:to_datetime) ? attributes[name].to_datetime : DateTime.parse(attributes[name].to_s)
          when nil
          else
            attributes[name] = attributes[name].send("to_#{options[:type]}".to_sym)
          end unless attributes[name].nil? && options[:allow_nil]
        end
        true
      else
        false
      end
    end

    private

    def calculate_id(attr)
      id_related_attributes = model_attributes.select { |key, value| value[:id] }.map(&:first)
      values = id_related_attributes.blank? ? attributes(model_attributes.keys - [:id]) : attributes(id_related_attributes)
      values.to_a.map { |x| x.map(&:to_s) }.sort { |a, b| a.first <=> b.first }.map(&:last).join("_")
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
          reader_command = "attributes[:#{attribute_name}]"
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
          writer_command = "attributes[:#{attribute_name}] = new_value"
          update_id_command = options[:id] ? "attributes[:id] = calculate_id(:#{attribute_name}); new_value" : ''
          visibility = options[:readonly] ? 'private' : 'public'
          visibility_command = "#{visibility}(:#{attribute_name}=)"
          class_eval(<<-EOS_ATTRIBUTE_WRITE, __FILE__, __LINE__ + 1)
            #{def_command}
              #{writer_command}
              #{update_id_command}
            end
            #{visibility_command}
          EOS_ATTRIBUTE_WRITE
        end
      end

      alias :attributes :attribute

      def create(*args)
        instance = new(*args)
        instance.save
        instance
      end

    end

  end

end
