require "test_helper"

class MarketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @market = markets(:one)
  end

  test "should get index" do
    get markets_url, as: :json
    assert_response :success
  end

  test "should create market" do
    assert_difference("Market.count") do
      post markets_url, params: { market: {  } }, as: :json
    end

    assert_response :created
  end

  test "should show market" do
    get market_url(@market), as: :json
    assert_response :success
  end

  test "should update market" do
    patch market_url(@market), params: { market: {  } }, as: :json
    assert_response :success
  end

  test "should destroy market" do
    assert_difference("Market.count", -1) do
      delete market_url(@market), as: :json
    end

    assert_response :no_content
  end
end
