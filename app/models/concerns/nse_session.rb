require 'capybara'
require 'capybara/dsl'

# Mock Browser class
class NseSession
  include Capybara::DSL

  def initialize(url)
    # Configure Capybara to use Selenium with Chrome
    Capybara.default_driver = :selenium_chrome
    load_page(url)
  end

  def load_page(url)
    visit(url) # Load the specified URL
    puts "Page title: #{page.title}" # Print the page title
  end

  def fetch_cookies
    cookies = page.driver.browser.manage.all_cookies
    cookies.each do |cookie|
      puts "Cookie: #{cookie[:name]} = #{cookie[:value]}"
    end
    close_browser
    cookies
  end

  def close_browser
    Capybara.reset_sessions! # Clear sessions and close browser
    puts "Browser closed."
  end
end
               
