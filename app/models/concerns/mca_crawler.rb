require 'capybara'
require 'capybara/dsl'

class McaCrawler
  include Capybara::DSL
  attr_accessor :driver

  def initialize
    @driver = Selenium::WebDriver.for :chrome
    driver.get("https://www.mca.gov.in/content/mca/global/en/mca/master-data/MDS.html")
  end

  def cin_map(cin_list)
    cin = 'L85110KA1954PLC000759'
    begin
      cin_data = fetch_cin_data(cin)
      form_data = {
        data: URI.decode_uri_component(cin_data),
        csrfToken: URI.decode_uri_component(csrf_token)
      }
      url = "https://www.mca.gov.in/bin/mca/mds/commonSearch?data=#{cin_data}"
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      headers = {
        "authority" => "www.mca.gov.in",
        "method" => "GET",
        "path" => "/bin/mca/mds/commonSearch?data=#{cin_data}",
        "scheme" => "https",
        "accept" => "application/json, text/javascript, */*; q=0.01",
        "accept-encoding" => "gzip, deflate, br, zstd",
        "accept-language" => "en-US,en;q=0.9,ta;q=0.8,en-GB;q=0.7",
        "cache-control" => "no-cache",
        "pragma" => "no-cache",
        "priority" => "u=1, i",
        "referer" =>"https =>//www.mca.gov.in/content/mca/global/en/mca/master-data/MDS.html",
        "sec-ch-ua" =>'"Chromium";v="128", "Not;A=Brand";v="24", "Google Chrome";v="128"',
        "sec-ch-ua-mobile" => "?0",
        "sec-ch-ua-platform" => '"macOS"',
        "sec-fetch-dest" => "empty",
        "sec-fetch-mode" => "cors",
        "sec-fetch-site" => "same-origin",
        "user-agent" =>
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
        "x-requested-with" => "XMLHttpRequest",
      }

      request = Net::HTTP::Post.new(uri.request_uri, headers)
      request.set_form_data(form_data)
      response = http.request(request)

  end

  def fetch_cin_data(cin)
    cin_data = driver.execute_script('return encrypt(arguments[0]);', "module=MDS&searchKeyWord=#{cin}&searchType=autosuggest&mdsSearchType=searchedName&mdsSearchType=company")
                                                                       module=MDS&searchKeyWord=#{cin}&searchType=autosuggest&mdsSearchType=searchedName&mdsSearchType=company&userInput=103&pre_CT=gPjezxgb8njL2I/d8m5aacwWuQ70lnEGY725UI7EoXkAuMV1cEP4Ppu2M9OQ4Ew3uxeP8ok7z0qnmyUc2fMwKxwNWZwTQ1D81T4=
    "module=MDS&searchKeyWord=&searchType=refine&limit=10&offset=0&compRegNo=" +
                  compRegNo +
                  "&ROC=" +
                  ROC +
                  "&state=" +
                  state +
                  "&userInput=" +
                  userValue +
                  "&pre_CT=" +
                  t__;
                $.ajax(
  end

  def csrf_token
    driver.execute_script('return encrypt(window.parent.document.querySelector("#csrfToken").value);' )
  end

end

  for (const cin of cinList) {
    try {
      cinData = await page.evaluate((cin) => {
        return encrypt(
          `module=MDS&searchKeyWord=${cin}&searchType=autosuggest&mdsSearchType=searchedName&mdsSearchType=company`
        );
      }, cin);
      config = {
        method: "get",
        maxBodyLength: Infinity,
        url: `https://www.mca.gov.in/bin/mca/mds/commonSearch?data=${cinData}`,
        headers = {
          authority: "www.mca.gov.in",
          method: "GET",
          path: `/bin/mca/mds/commonSearch?data=${cinData}`,
          scheme: "https",
          accept: "application/json, text/javascript, */*; q=0.01",
          "accept-encoding": "gzip, deflate, br, zstd",
          "accept-language": "en-US,en;q=0.9,ta;q=0.8,en-GB;q=0.7",
          "cache-control": "no-cache",
          pragma: "no-cache",
          priority: "u=1, i",
          referer:
            "https://www.mca.gov.in/content/mca/global/en/mca/master-data/MDS.html",
          "sec-ch-ua":
            '"Chromium";v="128", "Not;A=Brand";v="24", "Google Chrome";v="128"',
          "sec-ch-ua-mobile": "?0",
          "sec-ch-ua-platform": '"macOS"',
          "sec-fetch-dest": "empty",
          "sec-fetch-mode": "cors",
          "sec-fetch-site": "same-origin",
          "user-agent":
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
          "x-requested-with": "XMLHttpRequest",
        },
      };

      const resp = await axios.request(config);
      if (resp.status === 200) {
        data.push(resp.data.data);
        console.log(`Success fetching for ${cin}`);
      } else {
        errorList.push(cin);
        console.log(`Error fetching Mca info for ${cin}`);
      }
      await new Promise((resolve) => setTimeout(resolve, 1000));
    } catch (_e) {
      console.log(`Error fetching Mca info for ${cin}`);
      errorList.push(cin);
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
  try {
    console.log(errorList);
    const filePath = "/Users/jayaramr/Projects/puppeteer/mcaData12.json";
    let jsonData;
    if (data.length > 0) {
      jsonData = JSON.stringify(data, null, 2);

      fs.writeFile(filePath, jsonData, "utf8", (err) => {
        if (err) {
          console.error("Error writing to file:", err);
          return;
        }
        console.log("JSON object has been written to", filePath);
      });
    }

    await browser.close();
  } catch (_e) {
    console.log(errorList);
    console.log("====================================================");
    console.log(data);
  }
})();

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}
