module ActiveModel
  module Finders
    
    def self.included(base)
      base.send(:include, ActiveModel::Attributes)
      base.extend ClassMethods
    end

    module ClassMethods

      def method_missing(symbol, *args, &block)
        finder_match = ActiveModel::DynamicFinderMatch.match(symbol)
        if finder_match && finder_match.attribute_names.map(&:to_sym).all? { |attribute_name| model_attributes.has_key?(attribute_name) }
          if args.size < finder_match.attribute_names.size
            finder_match.finder == :all ? [] : nil
          else
            attribute_hash = [finder_match.attribute_names, args[0..finder_match.attribute_names.size - 1]].transpose.inject(HashWithIndifferentAccess.new) { |hash, av|hash[av.first.to_sym] = av.last; hash }
            if [:all, :first, :last].include?(finder_match.finder)
              find_matches attribute_hash, finder_match.finder
            else
              raise "Unknown finder #{finder_match.finder}"
            end
          end
        else
          super
        end
      end
      
      def respond_to?(symbol, include_private=false)
        finder_match = ActiveModel::DynamicFinderMatch.match(symbol)
        (finder_match && finder_match.attribute_names.map(&:to_sym).all? { |attribute_name| model_attributes.has_key?(attribute_name) }) ? true : super
      end

      def find(*ids)
        ids_array = ids.flatten
        rc = find_ids(ids_array).compact
        if ids_array.size > 1
          raise ActiveModel::RecordNotFound, "Couldn't find all #{self.name.pluralize} with IDs (#{ids.join(', ')}) (found #{rc.size} results, but was looking for #{ids_array.size})" unless rc.size == ids_array.size
        else
          raise ActiveModel::RecordNotFound, "Couldn't find #{self.name} with ID=#{ids.first}" if rc.blank?
          rc = rc.first unless ids.first.is_a?(Array)
        end
        rc
      end

        # Override this to what ever makes sense for your class
      def all
        []
      end

      # Override this only if this isn't efficient
      def count
        all.size
      end
      alias :size :count

      # Override this only if this isn't efficient
      def first
        all.first
      end

      # Override this only if this isn't efficient
      def last
        all.last
      end

      # Override this only if this isn't efficient
      def random
        all[rand(count)]
      end

      private

      # Override this as needed to work with the basic find.
      # ids will always be an array. Always return an array.
      # The caller will deal with raising any "not found" errors as needed. nil values will automatically be removed.
      def find_ids(ids)
        ids.inject([]) { |x, id| x << all.find { |y| y.id == id }}
      end

      private

      # This method allows for you to accept the attributes hash in all to do some early optimization.
      # It also allows all to retrieve based off of the attributes if your source cannot retrieve all records without some type of limiting parameters.
      def retrieve_all(attributes_hash, finder)
        case method(:all).arity
          when 0
            all
          when 1, -1
            all(attributes_hash)
          else
            all(attributes_hash, finder)
        end
      end

      # Attempt to convert all of the values of a search hash to the types they should be for a the model
      def duck_type_hash_values(hash)
        hash.inject(HashWithIndifferentAccess.new) do |corrected_hash, hash_entry|
          key = hash_entry.first
          value = hash_entry.last
          model_attribute = model_attributes[key.to_sym] || {}
          value = ActiveModel::Attributes.convert_to(model_attribute[:type], value) unless value.nil? && model_attribute[:allow_nil]
          corrected_hash[key] = value
          corrected_hash
        end
      end

      def find_matches(attribute_hash, finder)
        # Convert values given to the types specified in the model
        attribute_hash = duck_type_hash_values(attribute_hash)
        # Locate all attributes which are only aids to be passed as hints to the low level retrieve_all
        finder_aids = model_attributes.select { |name, options| options[:finder_aid] }.keys.map(&:to_s)
        # Identify all keys we will be comparing against
        keys = attribute_hash.keys - finder_aids.map(&:to_s)

        # Make the request to the low level retriever.
        all_values = retrieve_all(attribute_hash, finder)
        # Reverse the values if we are looking for the last match
        all_values.reverse! if finder == :last
        # Identify the ruby search command we will use to dig through the values
        search_command = (finder == :all) ? :select : :find

        # Pull out the final value(s) matching our search
        all_values.send(search_command) do |x|
          keys.inject(true) do |rc, key|
            rc && attribute_hash[key] == x.attributes[key]
          end
        end
      end

    end

  end
end