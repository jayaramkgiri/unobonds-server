
module ScripCrawlers

  def fetch_bse_scrip(new_isins, scraped_isins = {}, retry_count = 1)
    if retry_count > 5
      p "Retry limit reached. Failed to fetch bse scrips for #{new_isins}"
      return scraped_isins
    end
    scrip_map = {}
    bse_scrip_err = []
    new_isins.each do |isin|
      begin
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
            scrip_map[isin] = name
            p "Success ----- #{isin} --- #{name}"
          end
        else
          bse_scrip_err << isin
        end
        sleep(3)
      rescue => e
        p "Error fetching BSE scrip for #{isin} -> #{e}"
        bse_scrip_err << isin
      end
    end
    if bse_scrip_err.present?
      p "Failed to fetch bse_scrips for #{bse_scrip_err.count} ISINS"
      p "Retrying ...."
      sleep(retry_count * 5)
      p scrip_map
      fetch_bse_scrip(bse_scrip_err,  scrip_map, retry_count + 1)
    else
      scrip_map.merge(scraped_isins)
    end
  end

  def fetch_nse_scrip(new_isins, retry_count = 1)
    if retry_count > 5
      p "Retry limit reached. Failed to fetch bse scrips for #{new_isins}"
      return []
    end
    begin
      nse_scrip_map = {}
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
        return nse_scrip_map.slice(*new_isins)
      else
        puts "Failed to download file. HTTP Response: #{response.code} #{response.message}"
        p "Retrying ...."
        sleep(retry_count * 5)
        fetch_nse_scrip(new_isins, retry_count + 1)
      end
    rescue => e
      p "Error fetching NSE scrips -> #{e}"
      p "Retrying ...."
      sleep(retry_count * 5)
      fetch_nse_scrip(new_isins, retry_count + 1)
    end
  end

  def find_and_update_bse_scrips(scrips)
    bse_scrip_err = []
    scrips.each do |scrip|
      begin
        search_url = "https://api.bseindia.com/Msource/1D/getQouteSearch.aspx?Type=DB&text=#{scrip.upcase}&flag=site"
        search_response = Faraday.get(search_url) do |req|
          req.headers['Accept'] = 'application/json, text/plain, */*'
          req.headers['Accept-Encoding'] = 'gzip, deflate'
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
          body = decode_response_body(search_response)
          doc = Nokogiri::HTML.parse(body)
          if doc.search('a')[0].children[0].text == "No Match Found"
            p "Not found -------- #{isin}"
            nil
          else
            isin = doc.search('a')[0].children[2].children[1].text.gsub(" ", '')[0..11]
            p "Success ----- #{isin} --- #{scrip}"
            update_scrip_for_isin(isin, scrip)
          end
        else
          p "Error fetching BSE scrip for #{scrip} -> #{e}"
          bse_scrip_err << scrip
        end
        sleep(3)
      rescue => e
        p "Error fetching BSE scrip for #{scrip} -> #{e}"
        bse_scrip_err << scrip
      end
    end
      p bse_scrip_err
  end

  def decode_response_body(response)
    if response["content-encoding"] == 'gzip'
      Brotli.inflate(response.body)
    else
      response.body
    end
  end

  def update_scrip_for_isin(isin, scrip)
    iss = Issuance.where(isin: isin.upcase).first
    if iss.present?
      iss.update_attribute(:bse_scrip, scrip)
      p "Updated Scrip #{scrip} for isin #{isin}"
    else
      p "Issuance not found for scrip #{scrip}"
    end
  end
end