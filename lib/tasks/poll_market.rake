namespace :poll_market do
  desc "Run a looping task"
  task run: :environment do
    if Date.today.to_s.in? Market::HOLIDAYS_2025
      p "Market is closed today"
    else
      loop do
        current_time = Time.now 
        market_start = Time.new(current_time.year, current_time.month, current_time.day, 9, 15)
        market_end = Time.new(current_time.year, current_time.month, current_time.day, 15, 15)
        if current_time > market_end
          p "Market closed"
          break
        elsif current_time < market_start
          p "Waiting for Market to open"
        else
          p "Polling Market at #{current_time}"
          Market.update_marketdata
        end
        sleep(300)
      end
    end
  end
end