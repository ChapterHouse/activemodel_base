module ActiveModel

  if const_defined?("ActiveRecord")
    ActiveModelError = ActiveRecord::StandardError
    RecordNotFound = ActiveRecord::RecordNotFound
  else
    class ActiveModelError < StandardError
    end

    class RecordNotFound < ActiveModelError
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

  end

end
