class Market
  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, type: Date
  field :isin, type: String
  field :cin, type: String
  field :company_name, type: String
  field :description, type: String
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
  field :interest_frequency, type: String
  field :principal_frequency, type: String
  field :nse_scrip, type: String
  field :bse_scrip, type: String

  field :open, type: Float
  field :close, type: Float
  field :total_buy_order, type: Integer
  field :total_sell_order, type: Integer
  field :buyPrice, type: Float
  field :sellPrice, type: Float

  field :bse_scrape
  field :nse_scrape
end
