class Company
  include Mongoid::Document
  include Mongoid::Timestamps
  field :cin, type: String
  field :name, type: String
  field :status, type: String
  field :mca_sourced_date, type: Date

  field :mca_data
end
