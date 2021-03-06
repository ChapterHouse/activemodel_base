module ActiveModel
  
  # The real trick to the associations will be getting them to work seamlessly with ActiveRecord::Base subclasses
  module Associations

    # This is the class to handle the array of children from an association. We have to add the methods that ActiveRecord
    # adds to the array to allow things like concat, empty?, size, find, etc.
    # TODO: Add delayed retrieval.
    class AssociationProxy < ActiveSupport::BasicObject

      require "active_model_base/finders"
      include ::ActiveModel::Finders::ClassMethods

      # The options are the exact same that were used to establish the association. 
      # Sending the hash in eases the amount of information needed to be passed.
      def initialize(parent, association_options, children)
        @parent = parent
        @options = association_options
        @children = ::Array.wrap(children)
        @child_klass = association_options[:class_name].constantize
        @parent_key = association_options[:primary_key]
        @child_key = association_options[:foreign_key]
        @set_foreign_key = "#{@child_key}="
      end
    
      def method_missing(method, *args, &block)
#log("method_missing(#{method.inspect}, #{args.inspect}, #{block.inspect})") {
        begin
          super
        rescue ::NameError, ::NoMethodError => e
          @children.send(method, *args, &block)
        end
#}
      end
      
def puts(*args)
  ::Object.send(:puts, *args)
end

def log(*args, &block)
  ::Object.log(*args, &block)
end

      def build(*args)
        child = @child_klass.new(*args)
        concat child
        child
      end

      # TODO: Update to handle :dependant => :destroy and :dependant => :delete_all
      def clear
        @children.each do |child|
          child.send(@set_foreign_key, nil)
          child.save
        end
        @children = []
        self
      end

      def concat(*objects)
        parent_id = @parent.send(@parent_key)
    
        # Pull out the objects of the right class
        new_children = objects.flatten.find_all { |x| x.is_a?(@child_klass) }
        # Since we have no transaction support, this gets fun.
        # Set the keys all at once.
        new_children.each { |x| x.send(@set_foreign_key, parent_id) }
        # Append the new children to the existing array
        @children += new_children
        # Save everything as close to all at once as possible. If anything goes wrong we have a local copy of what should be at least.
        new_children.each { |x| x.save unless x.new_record? }

        self
      end
     
      alias :<< :concat 
      
      def create(*args)
        child = @child_klass.create(*args)
        concat child
        child
      end


      # TODO: Determine what AR does when it cannot find the item to delete.
      def delete(*objects)
        objects.flatten!
        # Oh how much we appreciate transactions.
        # You know, I wonder if something could be hand rolled to handle instances like this
        # or if we could somehow tap into the AR transactions outside of AR to reset the objects.
        # TODO: Check into handr olled or AR transactions.
        @children.delete_if { |child| objects.include?(child) }
        objects.each { |child| child.send(@set_foreign_key, nil) }
        objects.each(&:save)
        self
      end

private

      # These three are to support the finders on the proxy

      def model_attributes
        @child_klass.model_attributes
      end

      def retrieve_all(attributes_hash, finder)
        self
      end

      def all
        @children
      end

    end

    def self.included(base)
      base.send(:include, ActiveModel::Finders)
      base.extend ClassMethods
    end

    module ClassMethods

def print_commands(*commands)
  commands.each { |x| puts x }
end

      # Does not yet address build_association or create_association. (Soon though. has_any now has them. Just have to finish the tests for has_many.)
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
        # If the association is to be readonly then change the above to:
        # record = Author.find_by_id(author_id); record.readonly!; record
        finder_command = "record = #{finder_command}; record.readonly!; record" if options[:readonly]
        # public :author
        visibility_command = "public(:#{association})"

        # Add the above commands to the class to make the belongs to reader association
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
        visibility_command = "public(:#{association}=)"
        # self.author_id = new_author.try(:id)
        setter_command = "self.#{options[:foreign_key]} = new_value.try(:#{options[:primary_key].to_sym})"

        # Add the above commands to the class to make the belongs to writer association
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
        # Feel free to specify them if you wish. They will just be ignored, but there is no error thrown.

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

        # Here we make the magic methods that will allow the setting and reading of the associated models.
        # For explanation, assume the model is an Author and will belong to a Post

        # The name of the instance variable holding the association proxy. In the example it would be: @posts_proxy
        proxy = "@#{association}_proxy"

        # Create the associations reader command

        # def posts(force_reload=false)
        def_command = "def #{association}(force_reload=false)"

        #   if force_reload || @posts_proxy.nil? then
        if_load_needed = "if force_reload || #{proxy}.nil? then"
        #     children = Post.find_all_by_author_id(id)        
        finder_command = "children = #{options[:class_name]}.find_all_by_#{options[:foreign_key]}(#{options[:primary_key]})"
        #     @posts_proxy = AssociationProxy.new(Post, {:options => 'From Above'}, children)
        proxy_command = "#{proxy} = AssociationProxy.new(self, #{options}, children)"
        #   end
        #   @posts_proxy
        # end
        # public :posts
        visibility_command = "public(:#{association})"

#print_commands def_command, "  " + if_load_needed, "    " + finder_command, "    " + proxy_command, "  end", "end", visibility_command

        # Add the above commands to the class to make the has many reader association
        class_eval(<<-EOS_HAS_MANY_READ, __FILE__, __LINE__ + 1)
          #{def_command}
            #{if_load_needed}
              #{finder_command}
              #{proxy_command}
            end
            #{proxy}
          end
          #{visibility_command}
        EOS_HAS_MANY_READ


        # Create the association_ids reader command

        command_name = association.to_s.singularize + "_ids"

        # def post_ids(force_reload=false)
        def_command = "def #{command_name}(force_reload=false)"
        #   posts(force_reload).map(&:id)
        map_command = "#{association}(force_reload).map(&:id)"
        # end
        # public :post_ids
        visibility_command = "public(:#{command_name})"

#print_commands def_command, "  " + map_command, "end", visibility_command

        # Add the above commands to the class to make the has many reader association
        class_eval(<<-EOS_HAS_MANY_READ_IDS, __FILE__, __LINE__ + 1)
          #{def_command}
            #{map_command}
          end
          #{visibility_command}
        EOS_HAS_MANY_READ_IDS

        # Create the associations writer command

        # def posts=(array)
        #   posts.clear        
        #   posts << array
        # end
        # public(:posts=)

        class_eval(<<-EOS_HAS_MANY_WRITE, __FILE__, __LINE__ + 1)
          def #{association}=(array)
            #{association}.clear
            #{association} << array
          end
          public(:#{association}=)
        EOS_HAS_MANY_WRITE



        # Create the association_ids writer command

        # def post_ids=(array)
        #   posts.clear        
        #   public :posts
        # end
        # public(:post_ids=)

        command_name = association.to_s.singularize + "_ids"


        # TODO: Determine what Active Record returns on this. The ids or the records?
        class_eval(<<-EOS_HAS_MANY_WRITE_IDS, __FILE__, __LINE__ + 1)
          def #{command_name}=(array_of_ids)
            self.#{association} = #{options[:class_name]}.find(array_of_ids)
            #{command_name}
          end
          public(:#{command_name}=)
        EOS_HAS_MANY_WRITE_IDS


      end
    end
    
  end
end