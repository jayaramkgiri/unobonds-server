class IssuancesController < ApplicationController
  before_action :set_issuance, only: %i[ show update destroy ]

  # GET /issuances
  # GET /issuances.json
  def index
    @issuances = Issuance.all
  end

  # GET /issuances/1
  # GET /issuances/1.json
  def show
  end

  # POST /issuances
  # POST /issuances.json
  def create
    @issuance = Issuance.new(issuance_params)

    if @issuance.save
      render :show, status: :created, location: @issuance
    else
      render json: @issuance.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /issuances/1
  # PATCH/PUT /issuances/1.json
  def update
    if @issuance.update(issuance_params)
      render :show, status: :ok, location: @issuance
    else
      render json: @issuance.errors, status: :unprocessable_entity
    end
  end

  # DELETE /issuances/1
  # DELETE /issuances/1.json
  def destroy
    @issuance.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_issuance
      @issuance = Issuance.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def issuance_params
      params.require(:issuance).permit(:isin, :cin)
    end
end
