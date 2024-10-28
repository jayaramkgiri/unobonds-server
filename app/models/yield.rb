class Yield
  include Mongoid::Document
  include Mongoid::Timestamps

  A_RATING = ['A', 'A+','A-']
  AA_RATING = ['AA', 'AA+','AA-']
  AAA_RATING = ['AAA', 'AAA+','AAA-']
  BBB_RATING = ['BBB', 'BBB+','BBB-']

  field :a_yield, type: BigDecimal
  field :aa_yield, type: BigDecimal
  field :aaa_yield, type: BigDecimal
  field :bbb_yield, type: BigDecimal
  field :calculated_date, type: Date

  class << self
    def create_yields
      return if self.where(calculated_date:  Date.today).count > 0
      self.create(
          calculated_date: Date.today,
          a_yield: calculate_yield(A_RATING),
          aa_yield: calculate_yield(AA_RATING),
          aaa_yield: calculate_yield(AAA_RATING),
          bbb_yield: calculate_yield(BBB_RATING)
        )
    end

    def calculate_yield(rating)
      price_turnover_product=0
      turnover_sum=0
      recently_traded_issuances.where(:latest_rating.in => rating).each do |iss|
        if iss.latest_nse_trade.present?
          price_turnover_product = price_turnover_product +(iss.latest_nse_trade['turnover'] * iss.latest_nse_trade['way'].to_f / 100)
          turnover_sum = turnover_sum + iss.latest_nse_trade['turnover']
        end
        if iss.latest_bse_trade.present?
          price_turnover_product = price_turnover_product +(iss.latest_bse_trade['turnover'] * iss.latest_bse_trade['way'].to_f / 100)
          turnover_sum = turnover_sum + iss.latest_bse_trade['turnover']
        end
      end
      price_turnover_product/turnover_sum*100
    end



    def recently_traded_issuances
      Issuance.where(:latest_trade_date.gt => Date.today - 1.month, :latest_rating_date.gt => Date.parse('01-01-2023') )
    end
  end
end
