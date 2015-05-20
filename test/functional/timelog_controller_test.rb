require File.expand_path('../../test_helper', __FILE__)

class TimelogControllerTest < ActionController::TestCase

  def setup
    @request.session[:user_id] = 2
  end

  test "index should have xlsx and pdf export links" do
    get :index
    assert_response :success

    assert_select '.other-formats' do
      assert_select 'a.xlsx', :text => /xlsx/i
      assert_select 'a.pdf', :text => /pdf/i
    end
  end

  test "index should respond to xlsx format" do
    get :index, :format => 'xlsx'
    assert_response :success
    assert_equal 'application/xlsx', response.content_type
  end

  test "index should respond to pdf format" do
    get :index, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', response.content_type
  end
end
