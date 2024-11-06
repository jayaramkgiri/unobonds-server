class Company
  include Mongoid::Document
  include Mongoid::Timestamps
  field :cin, type: String
  field :name, type: String
  field :status, type: String
  field :mca_sourced_date, type: Date
  field :active_issuances, type: Integer

  field :mca_data
  has_many :issuances, foreign_key: 'cin'
end
