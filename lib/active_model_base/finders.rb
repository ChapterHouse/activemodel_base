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
            case finder_match.finder
            when :all
              find_all attribute_hash
            when :first
              find_first attribute_hash
            when :last
              find_last attribute_hash
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
      # id will always be an array. Always return an array.
      # The caller will deal with raising any "not found" errors as needed. nil values will automatically be removed.
      def find_ids(ids)
        ids.inject([]) { |x, id| x << all.find { |y| y.id == id }}
      end

      # Override these last three as needed to work with the dynamic finder
      def find_all(attribute_hash)
        keys = attribute_hash.keys
        retrieve_all(attribute_hash, :all).select do |x|
          keys.inject(true) do |rc, key|
# We need some duck typing here so the incomming key should probably be converted to the attribute type.
            rc && (finder_aids.include?(key.to_sym) || Array.wrap(attribute_hash[key]).include?(x.attributes[key]))
          end
        end
      end

      def find_first(attribute_hash)
        retrieve_all(attribute_hash, :first).find { |x| x.attributes(attribute_hash.keys) == attribute_hash }
      end

      def find_last(attribute_hash)
        retrieve_all(attribute_hash, :last).reverse.find { |x| x.attributes(attribute_hash.keys) == attribute_hash }
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

    end

  end
end