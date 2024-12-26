namespace :master_replenish do
  desc "Issuance and otc Trades upto date"
  task run: :environment do
    Issuance.get_db_upto_date
    OtcTrade.pull_trades
    Yield.create_latest_yields(1.month)
  end
end