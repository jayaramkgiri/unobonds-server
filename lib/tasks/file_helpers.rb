module FileHelpers
  def download_all_securities_file
  url = URI("https://www.indiabondinfo.nsdl.com/bds-service/v1/public/bdsinfo/listofsecurities?type=Active")

  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true

  request = Net::HTTP::Get.new(url)
  request["Accept"] = "*/*"
  request["Accept-Encoding"] = "gzip, deflate, br, zstd"
  request["Accept-Language"] = "en-US,en;q=0.9,ta;q=0.8,en-GB;q=0.7"
  request["Cache-Control"] = "no-cache"
  request["Connection"] = "keep-alive"
  request["Content-Disposition"] = "attachment; filename=SailBig.tiff"
  request["Content-Type"] = "application/json; charset=utf-8"
  request["Host"] = "www.indiabondinfo.nsdl.com"
  request["Pragma"] = "no-cache"
  request["Referer"] = "https://www.indiabondinfo.nsdl.com/CBDServices/"
  request["Sec-Fetch-Dest"] = "empty"
  request["Sec-Fetch-Mode"] = "cors"
  request["Sec-Fetch-Site"] = "same-origin"
  request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"
  request["sec-ch-ua"] = "\"Google Chrome\";v=\"129\", \"Not=A?Brand\";v=\"8\", \"Chromium\";v=\"129\""
  request["sec-ch-ua-mobile"] = "?0"
  request["sec-ch-ua-platform"] = "\"macOS\""

  response = https.request(request)
  file = Tempfile.new(['securities', '.xlsx'], encoding: 'ascii-8bit')
  file.write(response.body)
  file
  end
end