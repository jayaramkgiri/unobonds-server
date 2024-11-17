class BseOtcTrades
  BASE_URL = 'https://www.bseindia.com/download/Bhavcopy/Debt'

  def fetch_report(date)
    @curr_date = date
    res = Faraday.get(report_url)
    if res.status == 200
      f = Tempfile.new(['report', '.zip'],encoding: 'ascii-8bit')
      f.write(res.body)
      extract(f)
      process_icdm
    else
      p "API failed"
    end
  end


  def process_icdm
    return [] unless @dest_path
    icdm_name = Dir.foreach(@dest_path).select {|f| f.include?('icdm')}.first
    if icdm_name.present?
      return SmarterCSV.process("#{@dest_path}/#{icdm_name}")
    else
      p "no icdm file present"
    end
  end

  def extract(zipfile)
    @dest_path = "#{Rails.root}/tmp/bse_trades/#{@curr_date.strftime("%d%m%Y")}"
    FileUtils.mkdir_p(@dest_path)
    Zip::File.open(zipfile.path) do |zipfile|
      zipfile.each do |f|
        f_name = f.name.split('/')[-1]
        f_path = File.join(@dest_path, f_name)
        zipfile.extract(f, f_path)
      end
    end
  end

  def report_url
    file_suffix = @curr_date.strftime("%d%m%Y")
    url = "#{BASE_URL}/DEBTBHAVCOPY#{file_suffix}.zip"
  end
end
