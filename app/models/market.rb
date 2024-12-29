class Market
  include Mongoid::Document
  include Mongoid::Timestamps
  extend ScripCrawlers

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
  
  MARKET_KEYS = [
    :open,
    :close,
    :total_buy_order,
    :total_sell_order,
    :buy_price,
    :sell_price,
    :buy_volume,
    :sell_volume,
  ]

  HOLIDAYS_2025 = ["2025-02-26", "2025-03-14", "2025-03-31", "2025-04-10", "2025-04-14", "2025-04-18", "2025-05-01", "2025-08-15", "2025-08-27", "2025-10-02", "2025-10-21", "2025-10-22", "2025-11-05", "2025-12-25"]

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
  field :buy_price, type: Float
  field :sell_price, type: Float
  field :buy_volume, type: Float
  field :sell_volume, type: Float

  field :market_depth

  field :bse_scrape
  field :nse_scrape

  class << self

    attr_accessor :latest_version

    def update_marketdata
      begin
        fetch_latest_version
        p "Latest version #{@latest_version}"
        nse_init
        update_nse_data
        bse_init
        update_bse_data
      rescue => e
        "Polling Failed with #{e}"
      end
    end

    def fetch_latest_version
      @latest_version = Market.where(date: Date.today).distinct(:version).sort.last || 1
    end

    def bse_init
      @bse_market ||= BseTrades.new
    end

    def nse_init
      @nse_market ||= NseTrades.new
    end

    def update_bse_data
      bse_scrape = @bse_market.fetch_trade_list
      today = Date.today
      err_isins = []
      p "Updating BSE Scrape"
      fix_bse_missing_scrips(bse_scrape.keys)
      Issuance.where(:bse_scrip.in => bse_scrape.keys.compact).each do |iss|
        begin
          # market_entry = Market.where(isin: iss.isin, date: today).first
          market_entry = Market.new(isin: iss.isin, date: today, version: latest_version + 1)
          assign_iss_attributes(iss, market_entry)
          market_entry.bse_scrape = bse_scrape[iss.bse_scrip]
          market_entry.populate_market
          market_entry.populate_market_depth
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

    def fix_bse_missing_scrips(scrips)
      missing_scrips = (scrips - Issuance.where(:bse_scrip.in => scrips.compact).pluck(:bse_scrip))
      p "Missing scrips #{missing_scrips}"
      find_and_update_bse_scrips(scrips)
    end

    def update_nse_data
      nse_scrape = @nse_market.fetch_trade_list
      return unless nse_scrape.present?
      today = Date.today
      err_isins = []
      p "Updating NSE Scrape"
      Issuance.where(:isin.in => nse_scrape.keys.compact).each do |iss|
        begin
          market_entry = Market.new(isin: iss.isin, date: today, version: latest_version + 1 )
          assign_iss_attributes(iss, market_entry)
          market_entry.nse_scrape = nse_scrape[iss.isin]
          market_entry.populate_market
          market_entry.populate_market_depth
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
      market_entry.version = 1
    end
  end

  def fetch_bse_buy_depth
    depth = []
    prices = bse_scrape['market_depth'].select {|k,v| k.include?("BPrice")}.values.try(:map) do |v|
      v.gsub(',', '').gsub('-','').to_f
    end.compact
    qty =  bse_scrape['market_depth'].select {|k,v| k.include?("BQty")}.values.try(:map) do |v|
      v.gsub(',', '').gsub('-','').to_i
    end.compact
    return depth if !prices.present? || !qty.present?
    prices.each_with_index do |p, i|
      depth << {'price' => p, 'quantity' => qty[i]}
    end
    depth
  end

  def fetch_bse_sell_depth
    depth = []
    prices = bse_scrape['market_depth'].select {|k,v| k.include?("SPrice")}.values.try(:map) do |v|
      v.gsub(',', '').gsub('-','').to_f
    end.compact
    qty =  bse_scrape['market_depth'].select {|k,v| k.include?("SQty")}.values.try(:map) do |v|
      v.gsub(',', '').gsub('-','').to_i
    end.compact
    return depth if !prices.present? || !qty.present?
    prices.each_with_index do |p, i|
      depth << {'price' => p, 'quantity' => qty[i]}
    end
    depth
  end

  def fetch_nse_buy_depth
    nse_scrape['market_depth']['marketDeptOrderBook']['bid'] || []
  end

  def fetch_nse_sell_depth
    nse_scrape['market_depth']['marketDeptOrderBook']['ask'] || []
  end

  def populate_market_depth
    depth = {'bse' => {}, 'nse'=> {}}
    if bse_scrape.present?
      depth['bse']['buy'] = fetch_bse_buy_depth
      depth['bse']['sell'] = fetch_bse_sell_depth
    end
    if nse_scrape.present?
      depth['nse']['buy'] = fetch_nse_buy_depth
      depth['nse']['sell'] = fetch_nse_sell_depth
    end
    self.market_depth = depth
  end

  def populate_market
    market = {}
    if nse_scrape.nil?
      market = fetch_bse_market if nse_scrape.nil?
    elsif bse_scrape.nil?
      market = fetch_nse_market
    else
      market = compare_market(fetch_bse_market, fetch_nse_market)
    end
    format_market(market)
    market.keys.each do |k|
      self.send("#{k}=", market[k])
    end
  end

  def format_market(market)
    MARKET_KEYS.each do |key|
      market[key] = nil if market[key] == 0
    end
    if market[:total_buy_order].nil?
      market[:buy_volume] = nil
      market[:buy_price] = nil
    end
    if market[:total_sell_order].nil?
      market[:sell_volume] = nil
      market[:sell_price] = nil
    end
  end

  def compare_market(bse, nse)
    {
      open: (bse[:open] > nse[:open] ? bse[:open] : nse[:open]),
      close: (bse[:close] > nse[:close] ? bse[:close] : nse[:close]),
      total_buy_order: (bse[:total_buy_order] + nse[:total_buy_order]),
      total_sell_order: (bse[:total_sell_order] + nse[:total_sell_order]),
      buy_price: (bse[:buy_price].to_f > nse[:buy_price].to_f ? bse[:buy_price] : nse[:buy_price]),
      sell_price: (bse[:sell_price].to_f > nse[:sell_price].to_f ? bse[:sell_price] : nse[:sell_price]),
      buy_volume: (bse[:buy_volume] + nse[:buy_volume]),
      sell_volume: (bse[:sell_volume] + nse[:sell_volume]),
    }
  end

  def fetch_bse_market
    buy_price = bse_buy_price
    sell_price = bse_buy_price
    {
      open: bse_scrape['open'].to_f,
      close: bse_scrape['close'].to_f,
      total_buy_order: bse_scrape['market_depth']['TotalBQty'].to_i,
      total_sell_order: bse_scrape['market_depth']['TotalSQty'].to_i,
      buy_price: buy_price,
      sell_price: sell_price,
      buy_volume: bse_scrape['market_depth']['TotalBQty'].to_i * buy_price.to_f,
      sell_volume: bse_scrape['market_depth']['TotalSQty'].to_i * sell_price.to_f
    }
  end

  def bse_buy_price
    value = bse_scrape['market_depth'].select {|k,v| k.include?("BPrice")}.values.try(:map) do |v|
      v.gsub(',', '').gsub('-','').to_f
    end.sort.last
    value && value  > 0 ? value : nil
  end

  def bse_sell_price
    value = bse_scrape['market_depth'].select {|k,v| k.include?("SPrice")}.values.try(:map) do |v|
      v.gsub(',', '').gsub('-','').to_f
    end.sort.first
    value && value > 0 ? value : nil
  end

  def fetch_nse_market
    buy_price = nse_scrape['market_depth']['marketDeptOrderBook']['bid'].pluck('price').try(:map, &:to_f).sort.last
    sell_price = nse_scrape['market_depth']['marketDeptOrderBook']['ask'].pluck('price').try(:map, &:to_f).sort.last
    {
      open: nse_scrape['open'].to_f,
      close: nse_scrape['close'].to_f,
      total_buy_order: nse_scrape['market_depth']['marketDeptOrderBook']['totalBuyQuantity'].to_i,
      total_sell_order: nse_scrape['market_depth']['marketDeptOrderBook']['totalSellQuantity'].to_i,
      buy_price: buy_price,
      sell_price: sell_price,
      buy_volume: nse_scrape['market_depth']['marketDeptOrderBook']['totalBuyQuantity'].to_i * buy_price.to_f,
      sell_volume: nse_scrape['market_depth']['marketDeptOrderBook']['totalSellQuantity'].to_i * sell_price.to_f
    }
  end
end
