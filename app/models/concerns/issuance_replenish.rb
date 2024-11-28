module IssuanceReplenish
  include NsdlCrawler
  include IssuanceRatings

  attr_accessor :new_isins, :denormalize_err_isins, :redeemed_isins, :file_data

  STANDARD_KEYS = ["Sr. No.",
  "ISIN",
  "Name of Issuer",
  "Series",
  "Security Description",
  "Type of Instrument",
  "Mode of Issue",
  "Category of Issue",
  "Face Value(in Rs.)",
  "Issue Size(in Rs.)",
  "Date of Allotment",
  "Date of Redemption/Conversion",
  "Coupon Rate (%)",
  "Coupon Type",
  "Frequency of Interest Payment",
  "Credit Rating",
  "Business Sector",
  "Type of Issuer-Ownership",
  "Type of Issuer-Nature",
  "Instrument Status"] 

  KEY_FIELDS = ["cin",
    "company_name",
    "description",
    "face_value",
    "allotment_date",
    "redemption_date",
    "coupon",
    "coupon_type",
    "coupon_basis",
    "latest_rating",
    "latest_rating_agency",
    "latest_rating_date",
    "latest_rating_rationale",
    "day_count_convention",
    "interest_frequency",
    "issue_size",
    "perpetual"] 

  def get_db_upto_date
    file = download_all_securities_file
    p "Securities File downloaded"
    @file_data = parse_all_securities_xl(file.path)
    p "Parsed Data"
    if (STANDARD_KEYS - file_data[0].keys).present?
      p 'Error: file headers has changed'
    else
      update_isins
    end
  end

  private
    
    def parse_all_securities_xl(file_path)
      xlsx = Roo::Spreadsheet.open(file_path)
      sheet = xlsx.sheet(0)
      sheet.parse(headers: true)
    end

    def update_isins
      isins = file_data[1..-1].map {|row| row['ISIN']}
      existing_isins = Issuance.pluck(:isin)
      @new_isins = isins - existing_isins
      @redeemed_isins = existing_isins - isins
      create_new_isins
      update_nsdl_data
      denormalize_key_fields
      delete_old_isins
    end

    def create_new_isins
      new_data = file_data.select do |d|
        d["ISIN"].in? new_isins
      end
      p "Creating #{new_isins.count} Isins"
      new_data.each do |d|
        begin
          iss = Issuance.find_or_create_by!(isin: d['ISIN'])
          iss.update_attribute(:nse_data, d)
        rescue => e
          p "Error: Isin -> #{d['ISIN']} -> #{e}"
        end
      end
    end

    def update_nsdl_data
      data = nsdl_data(new_isins)
      p "Updating NSDL data for new Isins"
      data.each do |k,v|
        Issuance.where(isin: k).first.update_attribute(:nsdl_data, v)
      end
    end

    def denormalize_key_fields
      p "Denormalizing Key fields for new Isins"
      @denormalize_err_isins = []
      @failed_isins = []
      Issuance.where(:isin.in => new_isins).each do |iss|
        begin
          KEY_FIELDS.each do |att|
            iss.send("fetch_#{att}")
          end
          iss.save!
        rescue => e
          p "Failed to save #{iss.isin}"
          @denormalize_err_isins << iss.isin
        end
      end
      if @denormalize_err_isins.present?
        p "Failed to update attibutes on new Isins: "
        p @denormalize_err_isins 
      end
    end

    def delete_old_isins
      p "Deleting redeemed #{redeemed_isins.count} isins"
      # Issuance.where(:isin.in => redeemed_isins).destroy_all
    end

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