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

    def readonly!
      @readonly = true
    end

    def readonly?
      @readonly
    end

    def save
      raise ReadOnlyRecord if readonly?
      if valid?
        write_attribute(:id, calculated_id)
        true
      else
        false
      end
    end

  end

end
