json.extract! yield, :id, :created_at, :updated_at
json.url yield_url(yield, format: :json)
