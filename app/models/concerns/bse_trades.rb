
require 'capybara'
require 'capybara/dsl'

# Mock Browser class
class BseTrades
  include Capybara::DSL

  STANDARD_HEADERS = {
    "Security Code" => 'security_code',
    "Security Name" => "security_name",
    "Group" => 'group',
    "Credit Rating" => 'credit_rating',
    "LTP/Close" => 'close',
    "Change" => 'change',
    "Change%" => 'change_percent',
    "YTM % at LTP" => 'yield',
    "Open Price" => 'open',
    "High Price" => 'high',
    "Low Price" => 'low',
    "Total Traded Volume" => 'total_traded_volume',
    "Total turnover (Rs in Lakhs)" => 'total_turnover'
  } 

  FLOAT_KEYS = ["close", "change", "change_percent", "yield", "open", "high", "low", "total_traded_volume", "total_turnover"] 

  def initialize
    Capybara.default_driver = :selenium_chrome
    visit('https://www.bseindia.com/markets/debt/debt_corporate_EOD.aspx')
    @last_page = fetch_last_page
    @trades = []
  end

  def fetch_all_trades
    (1..@last_page).to_a.each do |page_no|
      begin
        fetch_trades(page_no)
      rescue => e
        p "#{e}"
      end
    end
    close_browser
    @trades
  end

  def fetch_last_page
    last_page_text = page.find(:css, 'table#ContentPlaceHolder1_GridViewrcdsFC').all('tr')[-1].all('td')[-1].text
    if last_page_text.to_i > 0
      last_page_text.to_i
    else
      raise 'Error fetching Page count'
    end
  end

  def fetch_trades(page_no)
    if page_no != 1
      navigate_to(page_no)
    end
    extract_data
  end

  def navigate_to(page_no)
    page.find(:css, 'table#ContentPlaceHolder1_GridViewrcdsFC').all('tr')[-1].all('td')[page_no-1].click
  end

  def extract_data
    validate_headers
    data = page.find(:css, 'table#ContentPlaceHolder1_GridViewrcdsFC').all('tr')[1..-3].map do |row|
      trade_hash(row)
    end
    @trades = @trades + data
  end

  def trade_hash(row)
    trade = {}
    row.all('td').each_with_index do |d, i|
      if STANDARD_HEADERS.values[i].in? FLOAT_KEYS
        trade[STANDARD_HEADERS.values[i]] = d.text.strip.present? ? d.text.strip.to_f : nil
      else
        trade[STANDARD_HEADERS.values[i]] = d.text.strip.present? ? d.text.strip : nil
      end
    end
    trade['security_info'] = security_info(trade['security_code'])
    trade['market_depth'] = market_depth(trade['security_code'])
    trade
  end

  def validate_headers
    headers = page.find(:css, 'table#ContentPlaceHolder1_GridViewrcdsFC').all('tr')[0].all('th').map {|h| h.text}
    raise 'Headers modified' unless headers == STANDARD_HEADERS.keys
    true
  end


  def market_depth(code)
    begin
      url = "https://api.bseindia.com/RealTimeBseIndiaAPI/api/MarketDepth/w?flag=&quotetype=EQ&scripcode=#{code}"
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request['accept'] = 'application/json, text/plain, */*'
      request['accept-encoding'] = 'gzip, deflate, br, zstd'
      request['accept-language'] = 'en-GB,en-US;q=0.9,en;q=0.8'
      request['cache-control'] = 'no-cache'
      request['priority'] = 'u=1, i'
      request['referer'] = 'https://www.bseindia.com/'
      request['sec-ch-ua'] = '"Chromium";v="130", "Google Chrome";v="130", "Not?A_Brand";v="99"'
      request['sec-ch-ua-mobile'] = '?0'
      request['sec-ch-ua-platform'] = '"macOS"'
      request['sec-fetch-dest'] = 'empty'
      request['sec-fetch-mode'] = 'cors'
      request['sec-fetch-site'] = 'same-site'
      request['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'
      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      else
        p "Error fetching market depth for #{code} --> API returned with code #{response.message}"
        nil
      end
    rescue => e
      p "Error fetching market depth for #{code} --> #{e}"
      nil
    end
  end

  def security_info(code)
    begin
      url = "https://api.bseindia.com/BseIndiaAPI/api/DebSecurityInfo/w?scripcode=#{code}"
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request['accept'] = 'application/json, text/plain, */*'
      request['accept-encoding'] = 'gzip, deflate, br, zstd'
      request['accept-language'] = 'en-GB,en-US;q=0.9,en;q=0.8'
      request['priority'] = 'u=1, i'
      request['referer'] = 'https://www.bseindia.com/'
      request['sec-ch-ua'] = '"Chromium";v="130", "Google Chrome";v="130", "Not?A_Brand";v="99"'
      request['sec-ch-ua-mobile'] = '?0'
      request['sec-ch-ua-platform'] = '"macOS"'
      request['sec-fetch-dest'] = 'empty'
      request['sec-fetch-mode'] = 'cors'
      request['sec-fetch-site'] = 'same-origin'
      request['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'

      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)['Table'][0]
      else
        p "Error fetching security info for #{code} --> API returned with code #{response.message}"
        nil
      end
    rescue => e
      p "Error fetching security info for #{code} --> #{e}"
      nil
    end
  end

  def close_browser
    Capybara.reset_sessions! # Clear sessions and close browser
    puts "Browser closed."
  end
end
               

