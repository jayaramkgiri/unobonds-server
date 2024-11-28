
module ScripHelpers

  def fetch_bse_scrip(new_isins)
    scrip_map = {}
    bse_scrip_err = []
    new_isins.each do |isin|
      search_url = "https://api.bseindia.com/Msource/1D/getQouteSearch.aspx?Type=DB&text=#{isin.upcase}&flag=site"
      search_response = Faraday.get(search_url) do |req|
        req.headers['Accept'] = 'application/json, text/plain, */*'
        req.headers['Accept-Encoding'] = 'gzip, deflate, br'
        req.headers['If-Modified-Since'] = 'Thu, 28 Sep 2023 14:06:18 GMT'
        req.headers['Sec-Ch-Ua'] = 'Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116'
        req.headers['Sec-Ch-Ua-Platform'] = 'macOS'
        req.headers['Sec-Fetch-Dest'] = 'empty'
        req.headers['Sec-Fetch-Mode'] = 'cors'
        req.headers['Sec-Fetch-Site'] = 'same-site'
        req.headers['Origin'] = 'https://www.bseindia.com'
        req.headers['Referer'] = 'https://www.bseindia.com/'
        req.headers['Accept-Language'] = 'en-GB,en-US;q=0.9,en;q=0.8'
        req.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36'
      end
      if search_response.status == 200
        doc = Nokogiri::HTML.parse(search_response.body)
        if doc.search('a')[0].children[0].text == "No Match Found"
          p "Not found -------- #{isin}"
          nil
        else
          name = doc.search('a')[0].children[2].children[0].text.gsub("\u00A0", "")
          # code = doc.search('a')[0].children[2].children[2].text.gsub("\u00A0", "")
          p "Success ----- #{isin} --- #{name}"
          scrip_map[isin] = name
        end
      else
        bse_scrip_err << isin
      end
      sleep(3)
    end
    [scrip_map, bse_scrip_err]
  end

  def fetch_nse_scrip(new_isins)
    nse_scrip_map = {}
    nse_scrip_err = new_isins
    url = "https://www.nseindia.com/api/liveBonds-traded-on-cm?type=bonds"
    cookies = NseSession.new("https://www.nseindia.com").fetch_cookies
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    request["authority"] = "www.nseindia.com"
    request["method"] = "GET"
    request["path"] = "/api/liveBonds-traded-on-cm?type=bonds"
    request["scheme"] = "https"
    request["accept"] = "application/json, text/javascript, */*; q=0.01"
    request["accept-encoding"] = "gzip, deflate, br, zstd"
    request["accept-language"] = "en-US,en;q=0.9,ta;q=0.8,en-GB;q=0.7"
    request["cache-control"] = "no-cache"
    request["pragma"] = "no-cache"
    request["priority"] = "u=1, i"
    request["referer"] = "api/liveBonds-traded-on-cm?type=bonds"
    request["sec-ch-ua"] = "\"Chromium\";v=\"124\", \"Google Chrome\";v=\"124\", \"Not-A.Brand\";v=\"99\""
    request["sec-ch-ua-mobile"] = "?0"
    request["sec-ch-ua-platform"] = "\"macOS\""
    request["sec-fetch-dest"] = "empty"
    request["sec-fetch-mode"] = "cors"
    request["sec-fetch-site"] = "same-origin"
    request["user-agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    request["x-requested-with"] = "XMLHttpRequest"
    request['cookie'] = "nsit=#{ cookies.find {|c| c[:name] == 'nsit'}[:value]}; nseappid=#{cookies.find {|c| c[:name] == 'nseappid'}[:value]}"

    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      p 'Processing result'
      data = JSON.parse(Brotli.inflate(response.body))['data']
      unless data.present?
        p "Empty file downloaded"
        return [nse_scrip_map, nse_scrip_err] unless data.present?
      end
      data.each do |d|
        d_isin = d['meta']['isin']
        next unless(d_isin.present? && d['meta']['symbol'].present? && d['meta']['debtSeries'].present?)
        nse_scrip_map[d_isin] = "#{d['meta']['symbol']}-#{d['meta']['debtSeries'].first}"
      end
      nse_scrip_err = []
    else
      puts "Failed to download file. HTTP Response: #{response.code} #{response.message}"
    end
    return [nse_scrip_map.slice(*new_isins), nse_scrip_err]
  end
end