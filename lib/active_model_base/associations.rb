module ActiveModel
  
  # The real trick to the associations will be getting them to work seamlessly with ActiveRecord::Base subclasses
  module Associations

    def self.included(base)
      base.send(:include, ActiveModel::Finders)
      base.extend ClassMethods
    end

    module ClassMethods

      # Does not yet address build_association or create_association
      def belongs_to(association, options={})
        options[:class_name] ||= association.to_s.classify
        options[:foreign_key] ||= association.to_s + "_id"
        options[:primary_key] ||= "id"
        options[:readonly] = false unless options.has_key?(:readonly)
        options[:id] = false unless options.has_key?(:id)
        options[:allow_nil] = true unless options.has_key?(:allow_nil)
        # These are options that are available in ActiveRecord::Base but have not yet been determined if they fit in ActiveModel::Base or how they will be implemented.
        # options[:validate] = false unless options.has_key?(:validate)
        # options[:autosave] = false unless options.has_key?(:autosave)
        # options[:touch] = false unless options.has_key?(:touch)
        # options[:polymorphic] = false unless options.has_key?(:polymorphic)

        # Here we make the magic methods that will allow the setting and reading of the associated model.
        # For explanation, assume the model is a Post and will belong to an Author

        # attribute :author_id, {:id => false, :allow_nil => true}
        attribute_command = "attribute :#{options[:foreign_key]}, {:id => #{options[:id].inspect}, :allow_nil => #{options[:allow_nil].inspect}}"
        # def author
        def_command = "def #{association}"
        # Author.find_by_id(author_id)
        finder_command = "#{options[:class_name]}.find_by_#{options[:primary_key]}(#{options[:foreign_key]})"
        # public :author
        visibility_command = "public(:#{association})"

        # Add the above commands to the class to make the blongs to reader association
        class_eval(<<-EOS_BELONGS_TO_READ, __FILE__, __LINE__ + 1)
          #{attribute_command}
          #{def_command}
            #{finder_command}
          end
          #{visibility_command}
        EOS_BELONGS_TO_READ

        # def author=(new_author)
        def_command = "def #{association}=(new_value)"
        # public :author=
        visibility = options[:readonly] ? 'private' : 'public'
        visibility_command = "#{visibility}(:#{association}=)"
        # self.author_id = new_author.try(:id)
        setter_command = "self.#{options[:foreign_key]} = new_value.try(:#{options[:primary_key].to_sym})"

        # We will always create the writer method so that it can be used internally if needed. We just make it private if it should act like it wasn't created.
        class_eval(<<-EOS_BELONGS_TO_WRITE, __FILE__, __LINE__ + 1)
          #{def_command}
            #{setter_command}
            new_value
          end
          #{visibility_command}
        EOS_BELONGS_TO_WRITE

      end

      def has_many(association, options={})
        options[:class_name] ||= association.to_s.classify
        options[:foreign_key] ||= self.name.underscore + "_id"
        options[:primary_key] ||= "id"
        options[:limit] = nil unless options.has_key?(:limit)
        options[:offset] ||= 0
        options[:readonly] = false unless options.has_key?(:readonly)
        options[:validate] = false unless options.has_key?(:validate)
        options[:id] = false unless options.has_key?(:id)

        # These are options that are available in ActiveRecord::Base but have not yet been determined if they fit in ActiveModel::Base or how they will be implemented.

#       options[:conditions]
#       options[:order]
#       options[:dependent]
#       options[:finder_sql]
#       options[:counter_sql]
#       options[:extend]
#       options[:include]
#       options[:group]
#       options[:having]
#       options[:select]
#       options[:as]
#       options[:through]
#       options[:source]
#       options[:uniq]
#       options[:inverse_of]


        attribute_name = association.to_s.singularize + "_ids"

        attribute_command = "attribute :#{attribute_name}}, {:id => #{options[:id].inspect}, :read_only => #{options[:readonly].inspect}}"
        def_command = "def #{association}(force_reload='not_implemented')"
        finder_command = "#{options[:class_name]}.find_by_#{options[:foreign_key]}(#{options[:primary_key]})"
        visibility_command = "public(:#{association})"

        class_eval(<<-EOS_HAS_MANY_READ, __FILE__, __LINE__ + 1)
          #{attribute_command}
          #{def_command}
            #{finder_command}
          end
          #{visibility_command}
        EOS_HAS_MANY_READ

        method_name = "#{association}<<"
        def_command = "def #{method_name}(*objects)"
        append_command = "objects.each { |x| self.#{attribute_name} << x if x.is_a?(#{options[:class_name]}) }"
        visibility_command = "#{visibility}(:#{method_name})"

        class_eval(<<-EOS_HAS_MANY_APPEND, __FILE__, __LINE__ + 1)
          #{def_command}
            #{append_command}
            #{association}
          end
          #{visibility_command}
          alias :concat
        EOS_HAS_MANY_APPEND



      end
    end
    
  end
end