
require 'net/http'
require 'uri'
require 'tempfile'

# Define the URL
url = "https://www.nseindia.com/api/liveCorp-bonds?index=otctrades_listed&marketType=CBM&csv=true&selectValFormat=crores"

# Parse the URL
uri = URI.parse(url)

# Create a temporary file

begin
  # Initialize HTTP request
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  # Define GET request with headers
  request = Net::HTTP::Get.new(uri)
  request['authority'] = 'www.nseindia.com'
  request['method'] = 'GET'
  request['path'] = uri.request_uri
  request['scheme'] = 'https'
  request['accept'] = '*/*'
  request['accept-encoding'] = 'gzip, deflate, br, zstd'
  request['accept-language'] = 'en-GB,en-US;q=0.9,en;q=0.8'
  request['cookie'] = 'nsit=Mn5AQli6A_Y0QBVcNnsF0BX2; AKA_A2=A; defaultLang=en; _ga=GA1.1.133726627.1731665492; bm_mi=A54D9EED817FB31E8C67BD1E3B240ABC~YAAQq4zQF/oZCS2TAQAAQV5PLxlt0Xo4+dnWWZjj0z9hWYxRU76AZ7UrxvkF07L+v7iOxf9AbyFNpFO4Bw1opibBFrsmro9JLKims4NQ2qITwOXsXaUjLwbmCrW+Sgca5B1YyGf0DlgO4USx4ZMbBSc2DTDlG5R7649fhCfVF5Fcsn5w/Lf5FInepqXb7WvabkQ5BQ/rLH9m0swVlIUfQgJm9TO0mnzWojT4jQKjTDVpZNzLQayTwMdxzpYUJmki+4LKkLIDCvuDrAq+WupL5i21IaSt3/EIyzY2u8rjD/0nlfRGBTVv+wY5QBTr9Y9RHvK0euSRIdhuFqErttn5176HZEs6UHEzN2CoHQuRtJ5o4D/RRap8jZI=~1; _abck=DB62EE7A053991D5A06F63E139D34534~0~YAAQq4zQF/4ZCS2TAQAAxF5PLwzO6ZlYiYgK7+gVvbURoM9fg81gEc7wK6W4kqmXyDVXpzqloWg3ciPma1NATWU/Ypkf6ak4a67SIMPvf8oY2rWTvPIH+1/iOdtHWeIxTH3bjsb545wN4dLF5oOV+oqh6tvmFzQkjqW75CUqr0gBdTKIFYTOsIKiu/f9bn+inHavLTFiACvQRb307z4unbl5D3Vo+x/rB+5df481jW900CEqLdR12XpqMo/3pVNWkUqMz3pZswk5cqDfs9E03IupN+95XgzOegbXMg/V4xpURjXoMH5C1Dols0nIB8fTNv5ou/vFc91sbUVMui3m2f7DNkWgXBHt5jnuINMRLTEQP2SjVMa+Nf0YKk5XJG0DqVAKNFDfwK8G+0DihtVUdt5mMW8ETRisOWdOC1hUr2JPhxGo4jijXLCpI3sZn0pfxlerKsFrYxMv/RnpMWMR9i/g/fxOW6O2AViR4aKd2FTE1A==~-1~-1~-1; ak_bmsc=2E2CA88B6FA0EEFB15793134A737EA6C~000000000000000000000000000000~YAAQq4zQFyIaCS2TAQAAWWJPLxnmr6b/dlgowsMj+1Vef3q1IrpxW8GIjJcETVAZ9XChojkIRMoWauBJ92vBZuGhvOc57OZjfXQafgZMA6MX1au8L0niNzkf1Pdp5kmdXlvZCJfkfbLWLLXvikyeoWHDHptYi6u+zsON7Q5rlFgLa0DlXRddiL6HQsxJ6gALhEpudX7IKyOSlyuzFxYz+CGOenny0474Ks4YV0XhHeOmwdYz9FCdvM9bbtsdjbDDL8GRb7K1lfhQg1FAuVXr+ycax5nrqt4pkswqesdhEksCnd+lVIJ8yIbB/LZSbqdfTmSifDzTrkHI2Lo4G+/A+7ZWXT3G9QkrgWoOdpkWNllWwgxDy/6YLo1f28MkR6j7FR9g7ov+dVPBJs8lbp7HGqfXfraUpZCdOcpheQlMeNPGgzPhhhphaW+yZ8wf1e/FjzYmmE7EhDrBz550tmh1dcH3sJnmeaGAb/j6KDwpK3Cw5snb175mLSZSykEVUH95me+g4l+wLaK6VUn7cm/4uimf7EiRGK5I6xo=; nseappid=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcGkubnNlIiwiYXVkIjoiYXBpLm5zZSIsImlhdCI6MTczMTY2NTU1MywiZXhwIjoxNzMxNjcyNzUzfQ.JPQBL11f5N0lwTkRfERkgXapfOnvC9VQS9zjT6lKOCI; bm_sz=B889EE95B229B7467178028ABB32CD20~YAAQq4zQF1UaCS2TAQAAs2lPLxnT/aHHeQo/QlkQUpEzPuZfCB1heNQV2SQbG8S0Mg37F1WyMe/r770qhjmhzGUqwuQqOi8qrnMqPSZ2yBJ6/l/p+mWp4giCj0R94+FjqqIERIxlPB+6UEufjbWkIuRUCwMnqdfekD52cmHN7kCsfOGwFMBiWtFYpwqYfU+FByVjlO1mgb/yqgUbuFjxaxuQJNvHoy2FUOtPhpuZbaTMaDeQC2u4IN6nMuKnGGThS+69nDUHMndLMGDunjU8j9vca0Z69sOHvXIgmqMG9j13ncGYYjFzI/jowRTe7CX+Mx7rSA+murGvr4tb5CaKxn2SBLETADwfR5WgAkJhq3jAikpxz0p4UPf9VqrbjdO1o0JMidY06l7JzIXPJlodtBP++w2yG+kvvg==~4604471~3556915; _ga_87M7PJ3R97=GS1.1.1731665492.1.1.1731665553.60.0.0; _ga_WM2NSQKJEK=GS1.1.1731665492.1.1.1731665553.0.0.0; bm_sv=627EE2ACCB050013FFA2ECFA851CF644~YAAQq4zQF5YcCS2TAQAAQaVPLxlE6nNhAjOko9hx/6qN61x6aTyS4PGmgUzrAowwmQG+CWtRmzbZ738OBgEVf9OJs8lV2DR8VLLg5Sq+CdczCAso19PLNND8c2la55vkxORDXCR9Mk7dahx6Bx/FY+kIsieKcBlYrOO4a67UWrqKdG+GFWAbubslIA7s8fcFY6kxWKJFp02BOlTC7GSLBKEXWBya0CiCE+iN7oH2kBuaxXQFw1pivMJkZbhNAoVYiOVh~1; RT="z=1&dm=nseindia.com&si=0a37b9ac-7bd6-419e-9c9d-30b70dffe974&ss=m3ikx7lg&sl=3&se=8c&tt=2ux&bcn=%2F%2F684d0d47.akstat.io%2F&ld=1eub&nu=kpaxjfo&cl=1rqw"'
 # Replace with the cookie provided above
  request['priority'] = 'u=1, i'
  request['referer'] = 'https://www.nseindia.com/market-data/debt-market-reporting-corporate-bonds-traded-on-exchange'
  request['sec-ch-ua'] = '"Chromium";v="130", "Google Chrome";v="130", "Not?A_Brand";v="99"'
  request['sec-ch-ua-mobile'] = '?0'
  request['sec-ch-ua-platform'] = '"macOS"'
  request['sec-fetch-dest'] = 'empty'
  request['sec-fetch-mode'] = 'cors'
  request['sec-fetch-site'] = 'same-origin'
  request['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'
  request['x-requested-with'] = 'XMLHttpRequest'

  # Send the request
  response = http.request(request)

  # Check if the response is successful
  if response.is_a?(Net::HTTPSuccess)
    # Write the content to the temp file
    temp_file = Tempfile.new(['corporate_bonds', '.csv'], encoding: 'ASCII-8BIT')
    temp_file.write(Brotli.inflate(response.body))
    temp_file.close

    puts "File downloaded successfully!"
    puts "File saved at: #{temp_file.path}"
  else
    puts "Failed to download file. HTTP Response: #{response.code} #{response.message}"
  end
rescue StandardError => e
  puts "An error occurred: #{e.message}"
ensure
  # Cleanup
  temp_file.close if temp_file
end



CSV.foreach(temp_file.path, liberal_parsing: true) do |row|
  puts row.inspect
end