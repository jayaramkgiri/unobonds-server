class MarketsController < ApplicationController
  before_action :set_market, only: %i[ show update destroy ]

  # GET /markets
  # GET /markets.json
  def index
    @markets = Market.all
  end

  # GET /markets/1
  # GET /markets/1.json
  def show
  end

  # POST /markets
  # POST /markets.json
  def create
    @market = Market.new(market_params)

    if @market.save
      render :show, status: :created, location: @market
    else
      render json: @market.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /markets/1
  # PATCH/PUT /markets/1.json
  def update
    if @market.update(market_params)
      render :show, status: :ok, location: @market
    else
      render json: @market.errors, status: :unprocessable_entity
    end
  end

  # DELETE /markets/1
  # DELETE /markets/1.json
  def destroy
    @market.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_market
      @market = Market.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def market_params
      params.fetch(:market, {})
    end
end
