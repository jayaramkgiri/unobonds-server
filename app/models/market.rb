class Market
  include Mongoid::Document
  include Mongoid::Timestamps

  DENORMALIZED_FIELDS = [
  "cin",
  "company_name",
  "description",
  "face_value",
  "allotment_date",
  "redemption_date",
  "redemption_type",
  "coupon",
  "coupon_type",
  "coupon_basis",
  "latest_rating",
  "latest_rating_agency",
  "latest_rating_date",
  "interest_frequency",
  "principal_frequency"]   

  field :date, type: Date
  field :version, type: Integer

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

  class << self

    def update_marketdata
      update_nse_data
      update_bse_data
      populate_common_fields
    end

    def populate_common_fields
    end

    def update_bse_data
      bse_scrape = BseTrades.new.fetch_trade_list
      today = Date.today
      err_isins = []
      p "Updating BSE Scrape"
      Issuance.where(:isin.in => bse_scrape.keys.compact).each do |iss|
        begin
          market_entry = Market.where(isin: iss.isin, date: today).first
          market_entry = Market.new(isin: iss.isin, date: today) unless market_entry.present?
          assign_iss_attributes(iss, market_entry) if market_entry.new_record?
          market_entry.bse_scrape = bse_scrape[iss.isin]
          market_entry.save!
        rescue => e
          p "Failed to save BSE market data for #{iss.isin} -> #{e}"
          err_isins << iss.isin
        end
      end
      p "Completed BSE updates"
      if err_isins.present?
        p "BSE market update errors"
        p err_isins
      end
    end

    def update_nse_data
      nse_scrape = NseTrades.new.fetch_trade_list
      today = Date.today
      err_isins = []
      p "Updating NSE Scrape"
      Issuance.where(:isin.in => nse_scrape.keys.compact).each do |iss|
        begin
          market_entry = Market.where(isin: iss.isin, date: today).first
          market_entry = Market.new(isin: iss.isin, date: today) unless market_entry.present?
          assign_iss_attributes(iss, market_entry) if market_entry.new_record?
          market_entry.nse_scrape = nse_scrape[iss.isin]
          market_entry.save!
        rescue => e
          p "Failed to save NSE market data for #{iss.isin} -> #{e}"
          err_isins << iss.isin
        end
      end
      p "Completed NSE updates"
      if err_isins.present?
        p "NSE market update errors"
        p err_isins
      end
    end

    def assign_iss_attributes(iss, market_entry)
      DENORMALIZED_FIELDS.each do |f|
        iss_value = iss.send(f)
        market_entry.send("#{f}=", iss_value)
      end
    end
  end
end
