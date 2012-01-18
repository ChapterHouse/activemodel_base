module ActiveModel

  if const_defined?("ActiveRecord")
    ActiveModelError = ActiveRecord::StandardError
    AssociationTypeMismatch = ActiveRecord::AssociationTypeMismatch
    RecordNotFound = ActiveRecord::RecordNotFound
    ReadOnlyRecord = ActiveRecord::ReadOnlyRecord
  else
    class ActiveModelError < StandardError
    end

    class AssociationTypeMismatch < StandardError
    end

    class RecordNotFound < ActiveModelError
    end

    class ReadOnlyRecord < ActiveModelError
    end
  end

  class Base

    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Observing
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml
    include ActiveModel::Validations
    extend ActiveModel::Naming

    include ActiveModel::Associations

    def initialize(*args)
      @new_record = true
      super
    end

    def new_record?
      @new_record
    end

    def readonly!
      @readonly = true
    end

    def readonly?
      @readonly
    end

    def save
      raise ReadOnlyRecord if readonly?
      if valid?
        old_id = read_attribute(:id)
        write_attribute(:id, calculated_id)
        begin
          if self.class.save(self)
            @new_record = false 
            true
          else
            write_attribute(:id, old_id)
            false
          end
        rescue => e
          write_attribute(:id, old_id)
          raise e
        end          
      else
        false
      end
    end

    def self.create(*args)
      instance = new(*args)
      instance.save
      instance
    end

    # The save is moved to the class level so that the new_record marker to be set after the class defined store handling.
    # The store handling can return false or raise an exception to signify that the record was not stored.
    def self.save(record)
      false
    end

  end

end
