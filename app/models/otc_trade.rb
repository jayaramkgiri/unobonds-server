class OtcTrade
  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, type: Date
  field :isin, type: String
  field :weighted_average_price, type: Float
  field :weighted_average_yield, type: Float
  field :turnover, type: Float
  field :latest_rating, type: String
  field :latest_rating_agency, type: String
  field :latest_rating_date, type: Date
  field :allotment_date, type: Date
  field :redemption_date, type: Date
  field :bse_data
  field :nse_data

  class << self
    ISSUANCE_FIELDS = ['latest_rating', 'latest_rating_agency', 'latest_rating_date', 'allotment_date', 'redemption_date']

    def pull_trades(date = Date.yesterday)
      if trades_already_exists?(date)
        p "Trades already pulled"
      else
        pull_bse_trades(date)
        pull_nse_trades(date)
        update_other_fields(date)
      end
    end

    def pull_bse_trades(date)
      begin
        report = BseOtcTrades.new.fetch_report(date)
        traded_iss = Issuance.where(:isin.in => report.pluck(:"isin_no.")).only(['isin']+ISSUANCE_FIELDS ).to_a
        traded_isins = {}
        traded_iss.each {|t| traded_isins[t.isin] = t.attributes.slice(*ISSUANCE_FIELDS)}
        valid_isins = traded_isins.keys
        report.each do |r|
          unless r[:"isin_no."].in? valid_isins
            p "#{r[:"isin_no."]} not valid"
            next
          end
          iss= OtcTrade.where(isin: r[:"isin_no."], date: date).first
          iss = OtcTrade.new(isin: r[:"isin_no."], date: date) if iss.nil?
          r[:turnover] = r[:"turnover_(rs._lakh)"] * 100000
          iss.bse_data = r.slice(:weighted_average_yield, :weighted_average_price, :turnover)
          issue = traded_isins[r[:"isin_no."]]
          ISSUANCE_FIELDS.each {|f| iss.send("#{f}=", issue[f])}
          iss.save!
        end
      rescue => e
        p "Error fetching BSE trades --> #{e}"
      end
    end

    def pull_nse_trades(date)
      begin
        report = NseOtcTrades.new.fetch_report(date)
        exclusive_isins = report.pluck(:isin) - OtcTrade.where(:isin.in => report.pluck(:isin), :bse_data.ne=> nil).pluck(:isin)
        traded_iss = Issuance.where(:isin.in => exclusive_isins).only(['isin']+ISSUANCE_FIELDS ).to_a
        traded_isins = {}
        traded_iss.each {|t| traded_isins[t.isin] = t.attributes.slice(*ISSUANCE_FIELDS)}
        valid_isins = Issuance.where(:isin.in => report.pluck(:isin)).pluck(:isin)
        report.each do |r|
          unless r[:isin].in? valid_isins
            p "#{r[:isin]} not valid"
            next
          end
          iss= OtcTrade.where(isin: r[:isin], date: date).first
          iss = OtcTrade.new(isin: r[:isin], date: date) if iss.nil?
          iss.nse_data = r.slice(:weighted_average_yield, :weighted_average_price, :turnover)
          if r[:isin].in? exclusive_isins
            issue = traded_isins[r[:isin]]
            ISSUANCE_FIELDS.each {|f| iss.send("#{f}=", issue[f])}
          end
          iss.save!
        end
      rescue => e
        p "Error fetching NSE trades --> #{e}"
      end
    end


    def trades_already_exists?(date)
      self.where(date: date).count > 0
    end
  end
end
