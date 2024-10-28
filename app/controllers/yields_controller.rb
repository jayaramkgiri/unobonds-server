class YieldsController < ApplicationController
  before_action :set_yield, only: %i[ show update destroy ]

  # GET /yields
  # GET /yields.json
  def index
    @yields = Yield.all
  end

  # GET /yields/1
  # GET /yields/1.json
  def show
  end

  # POST /yields
  # POST /yields.json
  def create
    @yield = Yield.new(yield_params)

    if @yield.save
      render :show, status: :created, location: @yield
    else
      render json: @yield.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /yields/1
  # PATCH/PUT /yields/1.json
  def update
    if @yield.update(yield_params)
      render :show, status: :ok, location: @yield
    else
      render json: @yield.errors, status: :unprocessable_entity
    end
  end

  # DELETE /yields/1
  # DELETE /yields/1.json
  def destroy
    @yield.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_yield
      @yield = Yield.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def yield_params
      params.fetch(:yield, {})
    end
end
