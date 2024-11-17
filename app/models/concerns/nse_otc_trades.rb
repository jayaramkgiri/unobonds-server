# require 'capybara'
# require 'capybara/dsl'

class NseOtcTrades

  # include Capybara::DSL

  ONE_LAKH = 100000

  def fetch_report(date)
    resp = Faraday.get("https://archives.nseindia.com/archives/debt/cbm/cbm_trd#{date.strftime("%Y%m%d")}.csv")
    if resp.status == 200
      p 'Processing result'
      process_result(resp.body)
    else
      p "API failed"
    end
  end

  def process_result(res)
    trades =  []
    CSV.parse(res, headers: true).each do |r|
      trades << {
        isin: r["ISIN"].strip,
        weighted_average_yield: r["Weighted Average Yield (YTM) (%)"].to_f,
        weighted_average_price: r["Weighted Average Price  (Rs.)"].to_f,
        turnover: r["Total Trade Value (Rs. in lacs)"].to_f * ONE_LAKH
      }
    end
    trades
  end

  # BASE_URL = 'https://www.bseindia.com/download/Bhavcopy/Debt'

  # def initialize_browser
  #   Capybara.default_driver = :selenium_chrome
  # end

  # def load_page(url)
  #   visit(url) # Load the specified URL
  #   puts "Page title: #{page.title}" # Print the page title
  # end

  # def fetch_cookies
  #   @cookies ||= page.driver.browser.manage.all_cookies
  # end

  # def close_browser
  #   Capybara.reset_sessions! # Clear sessions and close browser
  #   puts "Browser closed."
  # end

  # def download_nse_otc_trade

  #   url = "https://www.nseindia.com/api/liveCorp-bonds?index=otctrades_listed&marketType=CBM&csv=true&selectValFormat=crores"
  #   uri = URI.parse(url)
  #   rows=[]

  #   initialize_browser
  #   load_page('https://www.nseindia.com')
  #   fetch_cookies
  #   close_browser

  #   begin
  #     http = Net::HTTP.new(uri.host, uri.port)
  #     http.use_ssl = true
  #     request = Net::HTTP::Get.new(uri)
  #     request['authority'] = 'www.nseindia.com'
  #     request['method'] = 'GET'
  #     request['path'] = uri.request_uri
  #     request['scheme'] = 'https'
  #     request['accept'] = '*/*'
  #     request['accept-encoding'] = 'gzip, deflate, br, zstd'
  #     request['accept-language'] = 'en-GB,en-US;q=0.9,en;q=0.8'
  #     request['cookie'] = "nsit=#{ @cookies.find {|c| c[:name] == 'nsit'}[:value]}; nseappid=#{@cookies.find {|c| c[:name] == 'nseappid'}[:value]}"
  #     request['priority'] = 'u=1, i'
  #     request['referer'] = 'https://www.nseindia.com/market-data/debt-market-reporting-corporate-bonds-traded-on-exchange'
  #     request['sec-ch-ua'] = '"Chromium";v="130", "Google Chrome";v="130", "Not?A_Brand";v="99"'
  #     request['sec-ch-ua-mobile'] = '?0'
  #     request['sec-ch-ua-platform'] = '"macOS"'
  #     request['sec-fetch-dest'] = 'empty'
  #     request['sec-fetch-mode'] = 'cors'
  #     request['sec-fetch-site'] = 'same-origin'
  #     request['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'
  #     request['x-requested-with'] = 'XMLHttpRequest'

  #     response = http.request(request)

  #     if response.is_a?(Net::HTTPSuccess)
  #       temp_file = Tempfile.new(['corporate_bonds', '.csv'], encoding: 'ASCII-8BIT')
  #       temp_file.write(Brotli.inflate(response.body))
  #       temp_file.close
  #       CSV.foreach(temp_file.path, liberal_parsing: true) do |row|
  #         rows << row.inspect
  #       end

  #       puts "File downloaded successfully!"
  #       puts "File saved at: #{temp_file.path}"
  #     else
  #       puts "Failed to download file. HTTP Response: #{response.code} #{response.message}"
  #     end
  #   rescue StandardError => e
  #     puts "An error occurred: #{e.message}"
  #   ensure
  #     # Cleanup
  #     temp_file.close if temp_file
  #   end
  #   rows
  # end
end
