module Cashflows
    def tradeable_issuances(scope = Issuance)
      scope.where(:bse_scrip.ne => nil).or( Issuance.where(:nse_scrip.ne => nil))
    end

    def fixed_interest_issuances(scope = Issuance)
      scope.where(coupon_basis:  "Fixed Interest" )
    end

    def issuances_with_day_count(scope = Issuance)
      scope.where(:day_count_convention.ne =>  nil)
    end

    def issuance_with_no_principal_redemption(scope)
      scope.in(redemption_type: ["Partial Redemption By Quantity", "Full Redemption"])
    end

    def issuance_with_proper_cfs(scope)
      scope.in(isin: scope.select do |iss|
        iss.redemption_date == last_payment_date(iss)
      end.pluck(:isin))
    end

    def attach_cashflows(scope)
      err_isins = []
      scope.each do |iss|
        begin
          dates = [iss.allotment_date] + iss.cash_flow_schedule.pluck(:payment_date).map(&:to_date).sort
          cf = generate_cashflows(dates, iss.coupon, iss.day_count_convention, iss.face_value)
          cf.each do |d, i|
            f = iss.cash_flow_schedule.find {|s| s[:payment_date].to_date == d}
            f["interest"] = i
          end
          last_schedule = iss.cash_flow_schedule.find {|s| s[:payment_date].to_date == cf.keys.last}
          last_schedule['principal'] = iss.face_value
          iss.save!
        rescue => e
          err_isins << iss.isin
        end
      end
      err_isins
    end
    
    def generate_cashflows(dates, coupon, day_count, face_value)
      cashflows = {}
      dates[1..-1].each_with_index do |date, index|
        prev_date = dates[index]
        interest = 0
        if day_count == "Actual/actual"
          interest = calculate_actual_by_actual_interest(face_value, coupon, prev_date, date)
        elsif day_count == "Actual/365"
          interest = calculate_actual_by_365_interest(face_value, coupon, prev_date, date)
        elsif day_count == "30/360"
          interest = calculate_30_by_360_interest(face_value, coupon, prev_date, date)
        end
        cashflows[date] = interest.round(2)
      end
      cashflows
    end

    def calculate_actual_by_actual_interest(face_value, coupon, prev_date, curr_date)
      denominator =  Date.leap?(curr_date.year) ? 366 : 365
      interest = ((face_value * coupon.to_f)/ (denominator * 100)) * (curr_date - prev_date)
    end

    def calculate_actual_by_365_interest(face_value, coupon, prev_date, curr_date)
      interest = ((face_value * coupon.to_f)/ (365 * 100)) * (curr_date - prev_date)
    end


    def calculate_30_by_360_interest(face_value, coupon, prev_date, curr_date)
      interest = ((face_value * coupon.to_f / 100) * (month_diff(prev_date, curr_date).to_f * 30 / 360))
    end

    def month_diff(prev_date, curr_date)
      month = (curr_date.year * 12 + curr_date.month) - (prev_date.year * 12 + prev_date.month)
    end

    def last_payment_date(iss)
      Date.parse(iss.cash_flow_schedule.pluck(:payment_date).sort.last)
    end

    def first_payment_date(iss)
      Date.parse(iss.cash_flow_schedule.pluck(:payment_date).sort.first)
    end
end