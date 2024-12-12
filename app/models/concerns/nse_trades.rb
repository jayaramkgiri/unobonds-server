class NseTrades

  attr_accessor :cookies

  def initialize
    @cookies = NseSession.new("https://www.nseindia.com").fetch_cookies
  end


  def fetch_trade_list
    begin
      url = "https://www.nseindia.com/api/liveBonds-traded-on-cm?type=bonds"
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request['accept'] = '*/*'
      request['accept-encoding'] = 'gzip, deflate, br, zstd'
      request['accept-language'] = 'en-GB,en-US;q=0.9,en;q=0.8'
      request['scheme'] = 'https'
      request['path'] = '/api/liveBonds-traded-on-cm?type=bonds'
      request['authority'] = 'www.nseindia.com'
      request['method'] = 'GET'
      request['cache-control'] = 'no-cache'
      request['pragma'] = 'no-cache'
      request['priority'] = 'u=1, i'
      request['referer'] = 'https://www.nseindia.com/market-data/bonds-traded-in-capital-market'
      request['sec-ch-ua'] = '"Chromium";v="130", "Google Chrome";v="130", "Not?A_Brand";v="99"'
      request['sec-ch-ua-mobile'] = '?0'
      request['sec-ch-ua-platform'] = '"macOS"'
      request['sec-fetch-dest'] = 'empty'
      request['sec-fetch-mode'] = 'cors'
      request['sec-fetch-site'] = 'same-site'
      request['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'
      request['cookie'] = "nsit=#{ cookies.find {|c| c[:name] == 'nsit'}[:value]}; nseappid=#{cookies.find {|c| c[:name] == 'nseappid'}[:value]}"
      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        augment_response JSON.parse(Brotli.inflate(response.body))
      else
        p "Error fetching Trade list. API responded with #{response.message}"
        nil
      end
    rescue => e
      p "Error fetching Trade list. Error --> #{e}"
      nil
    end
  end

  def augment_response(response)
    p "Building Trade Hash for #{response['data'].count}"
    trade_hash = {}
    response['data'].each do |d|
      p "Fetching Market Depth of #{d['symbol']}-#{d['series']}"
      d['market_depth'] = fetch_market_depth(d['symbol'], d['series'])
      trade_hash[d['meta']['isin']] = d
    end
    trade_hash
  end

  def fetch_market_depth(symbol, series)
    begin 
      url = "https://www.nseindia.com/api/quote-bonds?index=#{symbol}"
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request['accept'] = '*/*'
      request['accept-encoding'] = 'gzip, deflate, br, zstd'
      request['accept-language'] = 'en-GB,en-US;q=0.9,en;q=0.8'
      request['scheme'] = 'https'
      request['path'] = 'api/quote-bonds'
      request['authority'] = 'www.nseindia.com'
      request['method'] = 'GET'
      request['cache-control'] = 'no-cache'
      request['pragma'] = 'no-cache'
      request['priority'] = 'u=1, i'
      request['referer'] = 'https://www.nseindia.com/market-data/bonds-traded-in-capital-market'
      request['sec-ch-ua'] = '"Chromium";v="130", "Google Chrome";v="130", "Not?A_Brand";v="99"'
      request['sec-ch-ua-mobile'] = '?0'
      request['sec-ch-ua-platform'] = '"macOS"'
      request['sec-fetch-dest'] = 'empty'
      request['sec-fetch-mode'] = 'cors'
      request['sec-fetch-site'] = 'same-site'
      request['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'
      request['cookie'] = "nsit=#{@cookies.find {|c| c[:name] == 'nsit'}[:value]}; nseappid=#{@cookies.find {|c| c[:name] == 'nseappid'}[:value]}"
      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        extract_series_data JSON.parse(Brotli.inflate(response.body)), symbol, series
      else
        p "Error fetching Market depth for #{symbol} #{series}. ApI responded with #{response.message}"
        nil
      end
    rescue => e
      p "Error fetching Market depth for #{symbol} #{series}. Error --> #{e}"
      nil
    end
  end

  def extract_series_data(response, symbol, series)
    response['data'].find do |d|
      d['allSecurities']['symbol'] == symbol && d['allSecurities']['series']
    end
  end
end