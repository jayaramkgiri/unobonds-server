module AllSecurity
  include FileHelpers
  include NsdlCrawler
  include IssuanceRatings

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

  FETCH_ATTRIBUTES=['cin',
  'company_name',
  'face_value',
  'allotment_date',
  'redemption_date',
  'coupon_basis',
  'coupon',
  'coupon_type',
  'latest_rating',
  'latest_rating_agency',
  'latest_rating_date',
  'day_count_convention',
  'interest_frequency']

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

  def parse_all_securities_xl(file_path)
    xlsx = Roo::Spreadsheet.open(file_path)
    sheet = xlsx.sheet(0)
    sheet.parse(headers: true)
  end

  def get_db_upto_date
    file = download_all_securities_file
    @file_data = parse_all_securities_xl(file.path)
    if (STANDARD_KEYS - file_data[0].keys).present?
      p 'Error: file headers has changed'
    else
      update_isins(file_data)
    end
  end

  def update_isins
    isins = @file_data[1..-1].map {|row| row['ISIN']}
    existing_isins = Issuance.pluck(:isin)
    new_isins = isins - existing_isins
    create_new_isins(new_isins)
    update_nsdl_data(new_isins)
    redeemed_isins = existing_isins - isins
    delete_old_isins(redeemed_isins)
  end

  def create_new_isins(new_isins)
    new_data = @file_data.select do |d|
      d["ISIN"].in? new_isins
    end
    new_data.each do |d|
      begin
        iss = Issuance.find_or_create_by!(isin: d['ISIN'])
        iss.update_attribute(:nse_data, d)
      rescue => e
        p "Error: Isin -> #{d['ISIN']} -> #{e}"
      end
    end
  end

  def update_nsdl_data(new_isins)
    data = nsdl_data(new_isins)
    data.each do |k,v|
      Issuance.where(isin: k).first.update_attribute(:nsdl_data, v)
    end
    denormalize_key_fields(new_isins)
  end

  def delete_old_isins(redeemed_isins)
    Issuance.where(:isin.in => redeemed_isins).destroy_all
  end

  def denormalize_key_fields(new_isins)
    @fetch_errors = {}
    @failed_isins = []
    KEY_FIELDS.each {|att| @fetch_errors[att.to_sym] = []}
    Issuance.where(:isin.in => new_isins).each do |iss|
      begin
        KEY_FIELDS.each do |att|
          iss.send("#{att}=", send("fetch_#{att}", iss))
        end
        iss.save!
      rescue => e
        p "Failed to save #{iss.isin}"
        @failed_isins << iss.isin
      end
    end
    p @fetch_errors 
  end

  def fetch_cin(iss)
    if iss.nsdl_data['ncd']['cin'].present?
      iss.nsdl_data['ncd']['cin']
    elsif fetch_company_name(iss).present? && Company.where(name: fetch_company_name(iss)).present?
      Company.where(name: fetch_company_name(iss)).first.cin
    else
      @fetch_errors[:cin] << iss.isin
      nil
    end
  end

  def fetch_company_name(iss)
    if iss.nsdl_data['ncd']['issuerName'].present? && (iss.nse_data['Name of Issuer'].upcase.strip == iss.nsdl_data['ncd']['issuerName'].upcase.strip)
      iss.nse_data['Name of Issuer'].upcase.strip
    else
      @fetch_errors[:company_name] << iss.isin
      nil
    end
  end

  def fetch_face_value(iss)
    if(iss.nse_data['Face Value(in Rs.)'].present? && (iss.nse_data['Face Value(in Rs.)'].to_i == iss.nsdl_data['instruments']['instrumentsVo']['instruments']['faceValue'].to_i))
      iss.nse_data['Face Value(in Rs.)'].to_i
    else
      @fetch_errors[:face_value] << iss.isin
      nil
    end
  end

  def fetch_allotment_date(iss)
    if( iss.nsdl_data['instruments']['instrumentsVo']['instruments']['allotmentDate'].present? && ( iss.nsdl_data['instruments']['instrumentsVo']['instruments']['allotmentDate'].to_date == iss.nse_data['Date of Allotment'].to_date))
      iss.nse_data['Date of Allotment'].to_date
    else
      @fetch_errors[:allotment_date] << iss.isin
      nil
    end
  end

  def fetch_redemption_date(iss)
    if( iss.nsdl_data['instruments']['instrumentsVo']['instruments']['redemptionDate'].present? && ( iss.nsdl_data['instruments']['instrumentsVo']['instruments']['redemptionDate'].to_date == iss.nse_data["Date of Redemption/Conversion"].to_date))
      iss.nse_data["Date of Redemption/Conversion"].to_date
    else
      @fetch_errors[:redemption_date] << iss.isin
    end
  end

  def fetch_coupon(iss)
    if(iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponRate'].present? && (iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponRate'].to_f == iss.nse_data["Coupon Rate (%)"].to_f))
      iss.nse_data["Coupon Rate (%)"].to_f
    else
      @fetch_errors[:coupon] << iss.isin
      nil
    end
  end

  def fetch_coupon_type(iss)
    if(iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponType'].present? && (iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponType'] == iss.nse_data["Coupon Type"]))
      iss.nse_data["Coupon Type"]
    else
      @fetch_errors[:coupon_type] << iss.isin
      nil
    end
  end

  def fetch_coupon_basis(iss)
    if(iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponBasis'].present?)
      iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponBasis']
    else
      @fetch_errors[:coupon_basis] << iss.isin
      nil
    end
  end

  def fetch_latest_rating(iss)
    if iss.nsdl_data['rating']['currentRatings'].present?
      lr = iss.nsdl_data['rating']['currentRatings'].sort_by do |h|
        begin
          h['creditRatingDate'].to_date
        rescue => _e
          iss.allotment_date
        end
      end.last['currentRating']
      map_rating(lr)
    else
      @fetch_errors[:latest_rating] << iss.isin
      nil
    end
  end

  def fetch_latest_rating_agency(iss)
    if iss.nsdl_data['rating']['currentRatings'].present?
      la= iss.nsdl_data['rating']['currentRatings'].sort_by do |h|
        begin
          h['creditRatingDate'].to_date
        rescue => _e
          iss.allotment_date
        end
      end.last['creditRatingAgencyName']
      map_agency(la)
    else
      @fetch_errors[:latest_rating_agency] << iss.isin
      nil
    end
  end

  def fetch_latest_rating_date(iss)
    if iss.nsdl_data['rating']['currentRatings'].present?
      iss.nsdl_data['rating']['currentRatings'].sort_by do |h|
        begin
          h['creditRatingDate'].to_date
        rescue => _e
          iss.allotment_date
        end
      end.last['creditRatingDate'].to_date
    else
      @fetch_errors[:latest_rating_date] << iss.isin
      nil
    end
  end

  def fetch_day_count_convention(iss)
    if iss.nsdl_data['coupon'] && iss.nsdl_data['coupon']['coupensVo'] && iss.nsdl_data['coupon']['coupensVo']['couponDetails'] && iss.nsdl_data['coupon']['coupensVo']['couponDetails']['dayCountConvention']
      iss.nsdl_data['coupon']['coupensVo']['couponDetails']['dayCountConvention']
    else
      @fetch_errors[:day_count_convention] << iss.isin
      nil
    end
  end

  def fetch_interest_frequency(iss)
    if(iss.nsdl_data['coupon']['coupensVo']['couponDetails']['interestPaymentFrequency'].present? && (iss.nsdl_data['coupon']['coupensVo']['couponDetails']['interestPaymentFrequency'] == iss.nse_data["Frequency of Interest Payment"]))
      iss.nse_data["Frequency of Interest Payment"]
    else
      @fetch_errors[:interest_frequency] << iss.isin
      nil
    end
  end

  def fetch_description(iss)
    if iss.nsdl_data['instruments']['instrumentsVo']['instruments']['instrumentDesc'].present?
      iss.nsdl_data['instruments']['instrumentsVo']['instruments']['instrumentDesc']
    else
      @fetch_errors[:description] << iss.isin
    end
  end

  def fetch_latest_rating_rationale(iss)
    if iss.nsdl_data['rating']['currentRatings'].present?
      iss.nsdl_data['rating']['currentRatings'].sort_by do |h|
        begin
          h['creditRatingDate'].to_date
        rescue => _e
          iss.allotment_date
        end
      end.last['pressReleaseLink']
    else
      @fetch_errors[:latest_rating_rationale] << iss.isin
      nil
    end
  end

  def fetch_issue_size(iss)
    if iss.nsdl_data['instruments']['instrumentsVo']['instruments']['totalIssueSize'].present?
      iss.nsdl_data['instruments']['instrumentsVo']['instruments']['totalIssueSize'].to_i
    else
      @fetch_errors[:issue_size] << iss.isin
    end
  end

  def fetch_perpetual(iss)
    if iss.nsdl_data['instruments']['instrumentsVo']['instruments']['perpetualInNature'].present?
      iss.nsdl_data['instruments']['instrumentsVo']['instruments']['perpetualInNature'] == "Yes" ? true : false 
    else
      @fetch_errors[:perpetual] << iss.isin
    end
  end
end



# iss.nsdl_data['coupon']['coupensVo']['cashFlowScheduleDetails']['cashFlowSchedule']