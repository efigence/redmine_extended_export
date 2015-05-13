require File.expand_path('../../test_helper', __FILE__)

class IssuesControllerTest < ActionController::TestCase

  def setup
    @request.session[:user_id] = 2
  end

  test "index should have xlsx export link" do
    get :index
    assert_response :success
    assert_select '.other-formats' do
      assert_select 'a.xlsx', :text => /xlsx/i
    end
  end

  test "index should respond to xlsx format" do
    get :index, :format => 'xlsx'
    assert_response :success
    assert_equal 'application/xlsx', response.content_type
  end

  test "exported index should include comments if requested" do
    get :index, format: 'csv', comments: '1'
    assert_response :success
    assert_equal "text/csv; header=present", response.content_type
    assert response.body.starts_with?("#,")
    assert response.body.include? 'Comment'
    assert response.body.include? journals(:comment).notes
  end

  test "exported index shouldn't include comments if not requested" do
    get :index, format: 'csv'
    assert_response :success
    assert_not response.body.include? 'Comment'
    assert_not response.body.include? journals(:comment).notes
  end

  test "show page should have export links for subtasks if exist" do
    get :show, :id => 1
    assert_response :success
    assert_select '#subtasks-export .other-formats' do
      assert_select 'a.csv', :text => /csv/i
      assert_select 'a.xlsx', :text => /xlsx/i
      assert_select 'a.pdf', :text => /pdf/i
    end
    assert_select_related_issues_export
  end

  test "show page shouldn't have export links for subtasks if there are none" do
    get :show, :id => 5
    assert_response :success
    assert_select "#subtasks-export", false, "Export link shouldn't be present as there are no subtasks"
    assert_select_related_issues_export
  end

  private

  def assert_select_related_issues_export
    assert_select '#related-export .other-formats' do
      assert_select 'a.csv', :text => /csv/i
      assert_select 'a.xlsx', :text => /xlsx/i
      assert_select 'a.pdf', :text => /pdf/i
    end
  end
end
