class Yield
  include Mongoid::Document
  include Mongoid::Timestamps

  A_RATING = ['A', 'A+','A-']
  AA_RATING = ['AA', 'AA+','AA-']
  AAA_RATING = ['AAA', 'AAA+','AAA-']
  BBB_RATING = ['BBB', 'BBB+','BBB-']

  TENOR_BUCKETS = {
    '0-3' => [0,3],
    '3-5' => [3,5],
    '5-10' => [5,10],
    '10+' => [10, 99]
  }

  field :a_yield, type: Float
  field :aa_yield, type: Float
  field :aaa_yield, type: Float
  field :bbb_yield, type: Float
  field :calculated_date, type: Date
  field :tenor_bucket, type: String

  class << self
    def create_latest_yields(period)
      latest_trade_date = OtcTrade.latest_trade_date
      if self.where(calculated_date: latest_trade_date).count > 0
        p "Latest Yield already exists"
      else
        p "Calculating Yields" 
        TENOR_BUCKETS.keys.each do |tenor|
          self.create(
              calculated_date: latest_trade_date,
              tenor_bucket: tenor,
              a_yield: calculate_yield(A_RATING, tenor, period),
              aa_yield: calculate_yield(AA_RATING, tenor, period),
              aaa_yield: calculate_yield(AAA_RATING, tenor, period),
              bbb_yield: calculate_yield(BBB_RATING, tenor, period)
            )
        end
        p "Created latest Yield record" 
      end
    end

    def calculate_yield(rating, tenor, period)
      price_turnover_product=0
      turnover_sum=0
      OtcTrade.latest_trades(period).maturing_in(TENOR_BUCKETS[tenor][0].year, TENOR_BUCKETS[tenor][1].year).where(:latest_rating.in => rating).each do |iss|
        price_turnover_product = price_turnover_product + (iss.turnover * iss.weighted_average_yield / 100)
        turnover_sum = turnover_sum + iss.turnover
      end
      if turnover_sum > 0
        (price_turnover_product / turnover_sum * 100).round(2)
      else
        0
      end
    end
  end
end
