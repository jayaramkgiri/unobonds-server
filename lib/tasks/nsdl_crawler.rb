require "uri"
require "net/http"
require 'json'

module NsdlCrawler
  def nsdl_data(new_isins)
    urls = {
      ncd_base_url:  "https://www.indiabondinfo.nsdl.com/bds-service/v1/public/isins?isin=",
      instruments_base_url:  "https://www.indiabondinfo.nsdl.com/bds-service/v1/public/bdsinfo/instruments?isin=",
      coupon_base_url: "https://www.indiabondinfo.nsdl.com/bds-service/v1/public/bdsinfo/coupondetail?isin=",
      redemption_base_url: "https://www.indiabondinfo.nsdl.com/bds-service/v1/public/bdsinfo/redemptions?isin=",
      rating_base_url: "https://www.indiabondinfo.nsdl.com/bds-service/v1/public/bdsinfo/credit-ratings?isin=",
      listing_base_url: "https://www.indiabondinfo.nsdl.com/bds-service/v1/public/bdsinfo/credit-ratings?isin=",
      restructuring_base_url: "https://www.indiabondinfo.nsdl.com/bds-service/v1/public/bdsinfo/restructuring?isin=",
      default_base_url: "https://www.indiabondinfo.nsdl.com/bds-service/v1/public/bdsinfo/defaultdetail?isin=",
      documents_base_url: "https://www.indiabondinfo.nsdl.com/bds-service/v1/public/bdsinfo/keydocuments?isin="
    }

    data = {}

    err_isins = []
    not_found = []

    new_isins.each do |isin|
      data[isin] = {}
      skip_flag = false
      begin
        urls.each do |key, base_url|
          next if skip_flag
          url = URI("#{base_url}#{isin.upcase}")

          https = Net::HTTP.new(url.host, url.port)
          https.use_ssl = true

          request = Net::HTTP::Get.new(url)
          request["Accept"] = "application/json, text/plain, */*"
          request["Accept-Encoding"] = "gzip, deflate, br"
          request["Accept-Language"] = "en-US,en;q=0.9,ta;q=0.8,en-GB;q=0.7"
          request["Connection"] = "keep-alive"
          request["Host"] = "www.indiabondinfo.nsdl.com"
          request["Referer"] = "https://www.indiabondinfo.nsdl.com/CBDServices/"
          request["Sec-Fetch-Dest"] = "empty"
          request["Sec-Fetch-Mode"] = "cors"
          request["Sec-Fetch-Site"] = "same-origin"
          request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
          request["nonce"] = "039884652050240538181703227249069086970866|072370459103960684974062469884901346960427"
          request["sec-ch-ua"] = "\"Not/A)Brand\";v=\"99\", \"Google Chrome\";v=\"115\", \"Chromium\";v=\"115\""
          request["sec-ch-ua-mobile"] = "?0"
          request["sec-ch-ua-platform"] = "\"macOS\""

          response = https.request(request)
          obj = key.to_s.gsub('_base_url', '')

          data[isin][obj] = {}

          if response.code == "200" 
            body = JSON.parse(response.read_body)
            if key == :ncd_base_url && body["isin"].nil?
              not_found << isin
              p "#{isin}--->Not Found"
              skip_flag = true
            else
              data[isin][obj] = body
              p "#{isin}--->Success--->key: #{key}"
            end
          end
          if response.code != "200" && key == :ncd_base_url
            err_isins << isin
            skip_flag = true
          end

          if response.code != "200"
            p "#{isin}--->Error--->key: #{key} failed with #{response.code}"
          end
        end
      rescue => e
        p "#{isin}--->Exception--->message: #{e}"
        err_isins << isin
      end
    end
  end
end
