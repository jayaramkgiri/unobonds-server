module AllSecurity
  include FileHelpers
  include NsdlCrawler

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

  KEY_FIELDS = [
    :cin,
    :company_name,
    # :description,
    # :convertibility,
    :face_value,
    :allotment_date,
    :redemption_date,
    # :redemption_type,
    :coupon,
    :coupon_type,
    :coupon_basis,
    :latest_rating,
    :latest_rating_agency,
    :latest_rating_date,
    # :latest_rating_rationale,
    # :rating_at_issuance,
    # :rating_agency_at_issuance,
    :day_count_convention,
    :interest_frequency,
    # :principal_frequency,
    # :issue_size,
    # :issue_price,
    # :depository,
    # :perpetual,
  ]

  def reset_errors
    Issuance.fields.keys - ['_id', 'isin', 'nsdl_data', 'nse_data', 'created_at', 'updated_at'].each do |f|
      instance_variable_set("@#{f}_err", [])
    end
  end

  def parse_all_securities_xl(file_path)
    xlsx = Roo::Spreadsheet.open(file_path)
    sheet = xlsx.sheet(0)
    sheet.parse(headers: true)
  end

  def get_db_upto_date
    file = download_all_securities_file
    file_data = parse_all_securities_xl(file.path)
    if (STANDARD_KEYS - file_data[0].keys).present?
      p 'Error: file headers has changed'
    else
      update_isins(file_data)
    end
  end

  def update_isins(file_data)
    isins = file_data.map {|row| row['ISIN']}
    existing_isins = Issuance.pluck(:isin)
    new_isins = isins - existing_isins
    create_new_isins(new_isins)
    update_nsdl_data(new_isins)
    redeemed_isins = existing_isins - isins
    delete_old_isins(redeemed_isins)
  end

  def create_new_isins(new_isins, file_data)
    new_data = file_data.select do |d|
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

  def nse_trades(csv_path)
    trades = CSV.read(csv_path)
    nse_trades_hash = trades[1..-1].map do |t|
      {
        isin: t[1],
        wap: t[6],
        way: t[7],
        turnover: t[4].to_f*100000
      }
    end
    nse_trades_hash.each do |t|
      iss = Issuance.where(isin: t[:isin]).first
      next unless iss.present?
      iss.update_attribute(:latest_nse_trade, t.slice(:wap, :way, :turnover))
      iss.update_attribute(:latest_trade_date, Date.parse('11-Oct-2024'))
    end
  end

  def denormalize_key_fields(new_isins)
    iss.cin = 
  end

  def cin(iss)
    if iss.nsdl_data['ncd']['cin'].present?
      iss.nsdl_data['ncd']['cin']
    else
      @cin_err << iss.isin
      nil
    end
  end

  def company_name(iss)
    if iss.nsdl_data['ncd']['issuerName'].present? && (iss.nse_data['Name of Issuer'].upcase.strip == iss.nsdl_data['ncd']['issuerName'].upcase.strip)
      iss.nse_data['Name of Issuer'].upcase.strip
    else
      @company_name_err << iss.isin
      nil
    end
  end

  def face_value(iss)
    if(iss.nse_data['Face Value(in Rs.)'].present? && (iss.nse_data['Face Value(in Rs.)'].to_i == iss.nsdl_data['instruments']['instrumentsVo']['instruments']['faceValue'].to_i))
      iss.nse_data['Face Value(in Rs.)'].to_i
    else
      @face_value_err << iss.isin
      nil
    end
  end

  def allotment_date(iss)
    if( iss.nsdl_data['instruments']['instrumentsVo']['instruments']['allotmentDate'].present? && ( iss.nsdl_data['instruments']['instrumentsVo']['instruments']['allotmentDate'].to_date == iss.nse_data['Date of Allotment'].to_date))
      iss.nse_data['Date of Allotment'].to_date
    else
      @allotment_date_err << iss.isin
      nil
    end
  end

  def redemption_date(iss)
    if( iss.nsdl_data['instruments']['instrumentsVo']['instruments']['redemptionDate'].present? && ( iss.nsdl_data['instruments']['instrumentsVo']['instruments']['redemptionDate'].to_date == iss.nse_data["Date of Redemption/Conversion"].to_date))
      iss.nse_data["Date of Redemption/Conversion"].to_date
    else
      @redemption_date_err << iss.isin
    end
  end

  def redemption_date(iss)
    if( iss.nsdl_data['instruments']['instrumentsVo']['instruments']['redemptionDate'].present? && ( iss.nsdl_data['instruments']['instrumentsVo']['instruments']['redemptionDate'].to_date == iss.nse_data["Date of Redemption/Conversion"].to_date))
      iss.nse_data["Date of Redemption/Conversion"].to_date
    else
      @redemption_date_err << iss.isin
    end
  end

  def coupon(iss)
    if(iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponRate'].present? && (iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponRate'].to_f == iss.nse_data["Coupon Rate (%)"].to_f))
      iss.nse_data["Coupon Rate (%)"].to_f
    else
      @coupon_err << iss.isin
      nil
    end
  end

  def coupon_type(iss)
    if(iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponType'].present? && (iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponType'] == iss.nse_data["Coupon Type"]))
      iss.nse_data["Coupon Type"]
    else
      @coupon_type_err << iss.isin
      nil
    end
  end

  def coupon_basis(iss)
    if(iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponBasis'].present?)
      iss.nsdl_data['coupon']['coupensVo']['couponDetails']['couponBasis']
    else
      @coupon_basis_err << iss.isin
      nil
    end
  end

  def latest_rating(iss)
      iss.nsdl_data['rating']['currentRatings'].sort_by {|h| h['creditRatingDate'].to_date}.last['currentRating']
  end

  def latest_rating_agency(iss)
    iss.nsdl_data['rating']['currentRatings'].sort_by {|h| h['creditRatingDate'].to_date}.last['creditRatingAgencyName']
  end

  def latest_rating_date(iss)
    iss.nsdl_data['rating']['currentRatings'].sort_by {|h| h['creditRatingDate'].to_date}.last['creditRatingDate'].to_date
  end

  def day_count_convention(iss)
    iss.nsdl_data['coupon']['coupensVo']['couponDetails']['dayCountConvention']
  end

  def interest_frequency(iss)
    if(iss.nsdl_data['coupon']['coupensVo']['couponDetails']['interestPaymentFrequency'].present? && (iss.nsdl_data['coupon']['coupensVo']['couponDetails']['interestPaymentFrequency'] == iss.nse_data["Frequency of Interest Payment"]))
      iss.nse_data["Frequency of Interest Payment"]
    else
      @interest_frequency_mismatch << iss.isin
      nil
    end
  end

end


# Issuance.all.each do |iss|
#   begin
#     interest_frequency = interest_frequency(iss)
#   if interest_frequency.present?
#     iss.update_attribute(:interest_frequency, interest_frequency)
#   end
#   rescue => e
#     # p "Error-> #{iss.isin}"
#     @interest_frequency_err << iss.isin
#   end
# end


# Issuance.where(:latest_rating_agency.ne => nil ).each do |iss|
#   if agency_map.keys.include?(iss.latest_rating_agency)
#     iss.update_attribute(:latest_rating_agency, agency_map[iss.latest_rating_agency])
#   end
# end


# iss.nsdl_data['coupon']['coupensVo']['cashFlowScheduleDetails']['cashFlowSchedule']