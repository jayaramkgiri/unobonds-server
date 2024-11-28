class Issuance
  include Mongoid::Document
  include Mongoid::Timestamps

  extend IssuanceReplenish
  include FetchAttrHelpers

  field :isin, type: String
  field :cin, type: String
  field :company_name, type: String
  field :description, type: String
  field :convertibility, type: Boolean
  field :face_value, type: Float
  field :allotment_date, type: Date
  field :redemption_date, type: Date
  field :redemption_type, type: String
  field :coupon, type: Float
  field :coupon_type, type: String
  field :coupon_basis, type: String
  field :latest_rating, type: String
  field :latest_rating_agency, type: String
  field :latest_rating_date, type: Date
  field :latest_rating_rationale, type: String
  field :rating_at_issuance, type: String
  field :rating_agency_at_issuance, type: String
  field :day_count_convention, type: String
  field :interest_frequency, type: String
  field :principal_frequency, type: String
  field :issue_size, type: Float
  field :issue_price, type: Integer
  field :depository, type: String
  field :perpetual, type: Boolean
  field :nse_scrip, type: String
  field :bse_scrip, type: String
  field :latest_trade_date, type: Date

  field :cash_flow_schedule
  field :nsdl_data
  field :nse_data
  field :latest_bse_trade
  field :latest_nse_trade

  belongs_to :company, foreign_key: 'cin', optional: true


end

