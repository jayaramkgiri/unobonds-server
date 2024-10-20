module AllSecurity
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

  def reset_errors
    Issuance.fields.keys - ['_id', 'isin', 'nsdl_data', 'nse_data', 'created_at', 'updated_at'].each do |f|
      instance_variable_set("@#{f}_err", [])
    end
  end

  def parse_all_securities_xl(file_path)
    xlsx = Roo::Spreadsheet.open(file_path)
    sheet = xlsx.sheet(0)
    headers = sheet.headers.map {|h| h[0]}
    p "Warning: additional/unknown headers" if (STANDARD_KEYS - headers).present?
    sheet.parse(headers: true)
  end

  def push_to_db(nse_file_path)
    nse_data = parse_all_securities_xl(nse_file_path)
    nse_data[1..-1].each do |d|
      begin
        iss = Issuance.find_or_create_by!(isin: d['ISIN'])
        iss.update_attribute(:nse_data, d)
      rescue => e
        p "Error: Isin -> #{d['ISIN']} -> #{e}"
      end
    end
  end

  def bse_trades(csv_path)
    trades = CSV.read(csv_path)
    bse_trades_hash = trades[1..-1].map do |t|
      {
        isin: t[8],
        wap: t[5],
        way: t[6],
        turnover: t[7].to_f*100000
      }
    end
    bse_trades_hash.each do |t|
      iss = Issuance.where(isin: t[:isin]).first
      next unless iss.present?
      iss.update_attribute(:latest_bse_trade, t.slice(:wap, :way, :turnover))
      iss.update_attribute(:latest_trade_date, Date.parse('11-Oct-2024'))
    end
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




# Issuance.where(:isin.in => data1.keys).each do |iss|
#   begin
#   iss.nsdl_data = data1[iss.isin]
#   iss.save!
#   rescue => e
#     p "Error ---> #{iss.isin}"
#   end
# end

# iss.nsdl_data['coupon']['coupensVo']['cashFlowScheduleDetails']['cashFlowSchedule']