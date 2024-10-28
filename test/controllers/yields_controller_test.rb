require "test_helper"

class YieldsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @yield = yields(:one)
  end

  test "should get index" do
    get yields_url, as: :json
    assert_response :success
  end

  test "should create yield" do
    assert_difference("Yield.count") do
      post yields_url, params: { yield: {  } }, as: :json
    end

    assert_response :created
  end

  test "should show yield" do
    get yield_url(@yield), as: :json
    assert_response :success
  end

  test "should update yield" do
    patch yield_url(@yield), params: { yield: {  } }, as: :json
    assert_response :success
  end

  test "should destroy yield" do
    assert_difference("Yield.count", -1) do
      delete yield_url(@yield), as: :json
    end

    assert_response :no_content
  end
end
