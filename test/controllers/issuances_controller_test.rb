require "test_helper"

class IssuancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @issuance = issuances(:one)
  end

  test "should get index" do
    get issuances_url, as: :json
    assert_response :success
  end

  test "should create issuance" do
    assert_difference("Issuance.count") do
      post issuances_url, params: { issuance: { cin: @issuance.cin, isin: @issuance.isin } }, as: :json
    end

    assert_response :created
  end

  test "should show issuance" do
    get issuance_url(@issuance), as: :json
    assert_response :success
  end

  test "should update issuance" do
    patch issuance_url(@issuance), params: { issuance: { cin: @issuance.cin, isin: @issuance.isin } }, as: :json
    assert_response :success
  end

  test "should destroy issuance" do
    assert_difference("Issuance.count", -1) do
      delete issuance_url(@issuance), as: :json
    end

    assert_response :no_content
  end
end
