require File.expand_path('../../test_helper', __FILE__)

class SubtaskExportControllerTest < ActionController::TestCase

  def setup
    @request.session[:user_id] = 2
  end

  test "should get proper subtasks in csv" do
    get :subtasks, id: 1, format: 'csv', subject: '1'
    assert_response :success
    assert_equal "text/csv; header=present", response.content_type
    assert response.body.starts_with?("#")
    issues(:root).descendants.visible.pluck(:subject).each do |subject|
      assert response.body.include?(subject), "subject not included"
    end
  end

  test "should get subtasks in xlsx" do
    get :subtasks, id: 1, format: 'xlsx'
    assert_response :success
    assert_equal "application/xlsx", response.content_type
  end

  test "exported file should include comments if requested" do
    get :subtasks, id: 1, format: 'csv', comments: 1
    assert_response :success
    assert response.body.include? 'Comment'
    assert response.body.include? journals(:comment).notes
    assert_not response.body.include? 'Description'
  end

  test "exported file should include description if requested" do
    get :subtasks, id: 1, format: 'csv', description: 1
    assert_response :success
    assert_not response.body.include? 'Comment'
    assert_not response.body.include? journals(:comment).notes
    assert response.body.include? 'Description'
  end

  test "should return 406 if issue doesn't have any subtasks" do
    get :subtasks, id: 5, format: 'csv'
    assert_response :not_acceptable
  end

  test "should get proper related tasks in csv" do
    get :related, id: 5, format: 'csv', subject: '1'
    assert_response :success
    assert_equal "text/csv; header=present", response.content_type
    assert response.body.starts_with?("#")
    assert response.body.include? issues(:related).subject
  end

  test "should get proper related tasks in xlsx" do
    get :related, id: 5, format: 'xlsx'
    assert_response :success
    assert_equal "application/xlsx", response.content_type
  end

  test "should return 406 if issue doesn't have any related issues" do
    get :related, id: 1, format: 'csv'
    assert_response :not_acceptable
  end
end
