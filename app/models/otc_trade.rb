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

  scope :latest_trades, ->(period) {where(:date.gt => (OtcTrade.latest_trade_date - period))}
  scope :maturing_in, ->(start_period, end_period) {where(:redemption_date.lt => (OtcTrade.latest_trade_date + end_period), :redemption_date.gte => (OtcTrade.latest_trade_date + start_period))}

  class << self
    ISSUANCE_FIELDS = ['latest_rating', 'latest_rating_agency', 'latest_rating_date', 'allotment_date', 'redemption_date']

    def latest_trade_date
      OtcTrade.order_by(date: :desc).first.date
    end


    def pull_trades(date = Date.today)
      if trades_already_exists?(date)
        p "Trades already pulled"
      else
        p "Started BSE trades"
        bse= pull_bse_trades(date)
        p "Started NSE trades"
        nse = pull_nse_trades(date)
        if bse && nse
          p "Consolidating fields"
          update_top_fields(date)
          p "Completed pulling OTC trades"
        end
      end
    end

    def update_top_fields(date)
      OtcTrade.where(date: date).each do |tr|
        tr.calc_top_fields
        tr.save!
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
        p "BSE trades pulled"
        true
      rescue => e
        p "Error fetching BSE trades --> #{e}"
        false
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
        p "NSE trades pulled"
        true
      rescue => e
        p "Error fetching NSE trades --> #{e}"
        false
      end
    end


    def trades_already_exists?(date)
      self.where(date: date).count > 0
    end
  end

  def calc_top_fields
    if bse_data.nil?
      self.weighted_average_price = nse_data[:weighted_average_price] 
      self.weighted_average_yield = nse_data[:weighted_average_yield] 
      self.turnover = nse_data[:turnover]
    elsif nse_data.nil?
      self.weighted_average_price = bse_data[:weighted_average_price] 
      self.weighted_average_yield = bse_data[:weighted_average_yield] 
      self.turnover = bse_data[:turnover]
    else
      self.weighted_average_price = bse_data[:weighted_average_price] > nse_data[:weighted_average_price]  ? bse_data[:weighted_average_price] : nse_data[:weighted_average_price]
      self.weighted_average_yield = bse_data[:weighted_average_yield] > nse_data[:weighted_average_yield]  ? bse_data[:weighted_average_yield] : nse_data[:weighted_average_yield]
      self.turnover = bse_data[:turnover] + nse_data[:turnover]
    end
  end
end
