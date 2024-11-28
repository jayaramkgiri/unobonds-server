module IssuanceRatings

  ACCEPTED_RATINGS = ["AAA", "AA+", "AA", "AA-", "A+", "A", "A-", "BBB+", "BBB", "BBB-", "BB+", "BB", "BB-", "B+", "B", "B-", "CCC+", "CCC", "CCC-", "CC", "C", "D"] 

  RATINGS_MAP = {"PP-MLD C"=>"C",
    "PP-MLD  C"=>"C",
    "PP-MLD AA+"=>"AA+",
    "A-(CE)"=>"A-",
    "PP-MLD BBB-"=>"BBB-",
    "PP-MLD BBB+"=>"BBB+",
    "PP-MLD  BBB+"=>"BBB+",
    "PP-MLD  D"=>"D",
    "A(CE)"=>"A",
    "PP-MLD  A"=>"A",
    "PP-MLD  A+ (CE)"=>"A+",
    "BB+(CE)"=>"BB+",
    "PP-MLD A+"=>"A+",
    "PP-MLD AA"=>"AA",
    "PP-MLD AAA"=>"AAA",
    "AA-(CE)"=>"AA-",
    "AA+(CE)"=>"AA+",
    "PP-MLD  BBB"=>"BBB",
    "PP-MLD  A+"=>"A+",
    "WITHDRAWN"=>nil,
    "A+(CE)"=>"A+",
    "PP-MLD  AAA"=>"AAA",
    "PP-MLD  AA-"=>"AA-",
    "BBB-(CE)"=>"BBB-",
    "A+r(SO)"=>"A",
    "AAA(CE)"=>"AAA",
    "BB-(SO)"=>"BB-",
    "AA(CE)"=>"AA",
    "PP-MLD  BBB-"=>"BBB-",
    "PP-MLD AA-"=>"AA-",
    "PP-MLD  AA"=>"AA",
    "PP-MLD A"=>"A",
    "PP-MLD  AA+"=>"AA+",
    "PP-MLD B+"=>"B+",
    "PP-MLD  A-"=>"A-",
    "BBB+(CE)"=>"BBB+",
    "PP-MLD A-"=>"A-",
    "BB-(CE)"=>"BB-"} 

    ACCEPTED_AGENCIES = ["CARE RATINGS LIMITED",
      "ICRA LIMITED",
      "CRISIL RATINGS LIMITED",
      "ACUITE RATINGS AND RESEARCH LIMITED",
      "INDIA RATING AND RESEARCH PRIVATE LIMITED",
      "INFOMERICS VALUATION AND RATING PRIVATE LIMITED",
      "BRICKWORK RATINGS INDIA PRIVATE LIMITED"
    ] 
    
    
    AGENCY_MAP = {
      "Acuite Ratings And Research Limited" => "ACUITE RATINGS AND RESEARCH LIMITED",
      "INDIA RATING AND RESEARCH PVT. LTD" => "INDIA RATING AND RESEARCH PRIVATE LIMITED",
      "Infomerics Valuation and Rating Pvt. Ltd" => "INFOMERICS VALUATION AND RATING PRIVATE LIMITED",
      "CARE Ratings Limited" => "CARE RATINGS LIMITED",
      "ACUITE" => "ACUITE RATINGS AND RESEARCH LIMITED",
      "CREDIT ANALYSIS & RESEARCH LTD" => "CARE RATINGS LIMITED",
      "CRISIL LIMITED" =>  "CRISIL RATINGS LIMITED"
    }

    def map_rating(rating)
      if rating.in?(ACCEPTED_RATINGS)
        rating
      elsif rating.in?(RATINGS_MAP.keys)
        RATINGS_MAP[rating]
      else
        p "No map found for #{rating}"
        nil
      end
    end

    def map_agency(agency)
      if agency.in?(ACCEPTED_AGENCIES)
        agency
      elsif agency.in?(AGENCY_MAP.keys)
        AGENCY_MAP[agency]
      else
        p "No map found for #{agency}"
        nil
      end
    end
 end
