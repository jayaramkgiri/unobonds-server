module FetchAttrHelpers
  include IssuanceRatings

  def fetch_cin
    if self.nsdl_data['ncd']['cin'].present?
      self.cin = self.nsdl_data['ncd']['cin']
    elsif fetch_company_name.present? && Company.where(name: fetch_company_name).present?
      self.cin = Company.where(name: fetch_company_name).first.cin
    else
      raise 'Cin not found'
    end
  end

  def fetch_company_name
    if self.nsdl_data['ncd']['issuerName'].present? && (self.nse_data['Name of Issuer'].upcase.strip == self.nsdl_data['ncd']['issuerName'].upcase.strip)
      self.company_name = self.nse_data['Name of Issuer'].upcase.strip
    elsif self.nsdl_data['ncd']['formerNameOne'].present? || self.nsdl_data['ncd']['formerNameTwo'].present? || self.nsdl_data['ncd']['formerNameThree'].present?
      self.nsdl_data['ncd']['formerNameOne'] || self.nsdl_data['ncd']['formerNameTwo'] || self.nsdl_data['ncd']['formerNameThree']
    else
      raise 'Company name not found'
    end
  end

  def fetch_face_value
    if(self.nse_data['Face Value(in Rs.)'].present? && (self.nse_data['Face Value(in Rs.)'].to_f == self.nsdl_data['instruments']['instrumentsVo']['instruments']['faceValue'].to_f))
      self.face_value = self.nse_data['Face Value(in Rs.)'].to_i
    else
      raise 'Face Value not found'
    end
  end

  def fetch_allotment_date
    if( self.nsdl_data['instruments']['instrumentsVo']['instruments']['allotmentDate'].present? && ( self.nsdl_data['instruments']['instrumentsVo']['instruments']['allotmentDate'].to_date == self.nse_data['Date of Allotment'].to_date))
      self.allotment_date = self.nse_data['Date of Allotment'].to_date
    else
      raise 'allotment date not found'
    end
  end

  def fetch_redemption_date
    if( self.nsdl_data['instruments']['instrumentsVo']['instruments']['redemptionDate'].present? && ( self.nsdl_data['instruments']['instrumentsVo']['instruments']['redemptionDate'].to_date == self.nse_data["Date of Redemption/Conversion"].to_date))
      self.redemption_date = self.nse_data["Date of Redemption/Conversion"].to_date
    else
      raise 'redemption date not found'
    end
  end

  def fetch_coupon
    if(self.nsdl_data['coupon']['coupensVo']['couponDetails']['couponRate'].present? && (self.nsdl_data['coupon']['coupensVo']['couponDetails']['couponRate'].to_f == self.nse_data["Coupon Rate (%)"].to_f))
      self.coupon = self.nse_data["Coupon Rate (%)"].to_f
    else
      p "Coupon not found for #{isin}"
    end
  end

  def fetch_coupon_type
    if(self.nsdl_data['coupon']['coupensVo']['couponDetails']['couponType'].present? && (self.nsdl_data['coupon']['coupensVo']['couponDetails']['couponType'] == self.nse_data["Coupon Type"]))
      self.coupon_type = self.nse_data["Coupon Type"]
    else
      p "Coupon Type not found for #{isin}"
    end
  end

  def fetch_coupon_basis
    if(self.nsdl_data['coupon']['coupensVo']['couponDetails']['couponBasis'].present?)
      self.coupon_basis = self.nsdl_data['coupon']['coupensVo']['couponDetails']['couponBasis']
    else
      p "Coupon Basis not found for #{isin}"
    end
  end

  def fetch_latest_rating
    if self.nsdl_data['rating']['currentRatings'].present?
      lr = self.nsdl_data['rating']['currentRatings'].sort_by do |h|
        begin
          h['creditRatingDate'].to_date
        rescue => _e
          self.allotment_date
        end
      end.last['currentRating']
      self.latest_rating = map_rating(lr)
    else
      p "Latest Rating not found for #{isin}"
    end
  end

  def fetch_latest_rating_agency
    if self.nsdl_data['rating']['currentRatings'].present?
      la= self.nsdl_data['rating']['currentRatings'].sort_by do |h|
        begin
          h['creditRatingDate'].to_date
        rescue => _e
          self.allotment_date
        end
      end.last['creditRatingAgencyName']
      self.latest_rating_agency = map_agency(la)
    else
      p "Rating Agency not found for #{isin}"
    end
  end

  def fetch_latest_rating_date
    if self.nsdl_data['rating']['currentRatings'].present?
      self.latest_rating_date = self.nsdl_data['rating']['currentRatings'].sort_by do |h|
        begin
          h['creditRatingDate'].to_date
        rescue => _e
          self.allotment_date
        end
      end.last['creditRatingDate'].to_date
    else
      p "Rating Date not found for #{isin}"
    end
  end

  def fetch_day_count_convention
    if self.nsdl_data['coupon'] && self.nsdl_data['coupon']['coupensVo'] && self.nsdl_data['coupon']['coupensVo']['couponDetails'] && self.nsdl_data['coupon']['coupensVo']['couponDetails']['dayCountConvention']
      self.day_count_convention = self.nsdl_data['coupon']['coupensVo']['couponDetails']['dayCountConvention']
    else
      p "Day Count Convention not found for #{isin}"
    end
  end

  def fetch_interest_frequency
    if(self.nsdl_data['coupon']['coupensVo']['couponDetails']['interestPaymentFrequency'].present? && (self.nsdl_data['coupon']['coupensVo']['couponDetails']['interestPaymentFrequency'] == self.nse_data["Frequency of Interest Payment"]))
      self.interest_frequency = self.nse_data["Frequency of Interest Payment"]
    else
      p "Interest Frequency not found for #{isin}"
    end
  end

  def fetch_description
    if self.nsdl_data['instruments']['instrumentsVo']['instruments']['instrumentDesc'].present?
      self.description = self.nsdl_data['instruments']['instrumentsVo']['instruments']['instrumentDesc']
    else
      p "Description not found for #{isin}"
    end
  end

  def fetch_latest_rating_rationale
    if self.nsdl_data['rating']['currentRatings'].present?
      self.latest_rating_rationale =  self.nsdl_data['rating']['currentRatings'].sort_by do |h|
        begin
          h['creditRatingDate'].to_date
        rescue => _e
          self.allotment_date
        end
      end.last['pressReleaseLink']
    else
      p "Latest Rating Rationale not found for #{isin}"
    end
  end

  def fetch_issue_size
    if self.nsdl_data['instruments']['instrumentsVo']['instruments']['totalIssueSize'].present?
      self.issue_size = self.nsdl_data['instruments']['instrumentsVo']['instruments']['totalIssueSize'].to_f
    else
      p "Issue Size not found for #{isin}"
    end
  end

  def fetch_perpetual
    if self.nsdl_data['instruments']['instrumentsVo']['instruments']['perpetualInNature'].present?
      self.perpetual = self.nsdl_data['instruments']['instrumentsVo']['instruments']['perpetualInNature'] == "Yes" ? true : false 
    else
      p "Perpetual not found for #{isin}"
    end
  end
end