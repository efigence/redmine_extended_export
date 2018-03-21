require File.expand_path('../../test_helper', __FILE__)

class WikiControllerTest < ActionController::TestCase
  def setup
    @request.session[:user_id] = 2
    @project_id = projects(:projects_001).identifier
  end

  test 'index should have odt export link' do
    get :index, project_id: @project_id
    assert_response :success

    assert_select '.other-formats' do
      assert_select 'a.odt', text: /odt/i
    end
  end

  test 'show should have odt export link' do
    get :show, project_id: @project_id
    assert_response :success

    assert_select '.other-formats' do
      assert_select 'a.odt', text: /odt/i
    end
  end

  test 'show should respond to ODT format' do
    get :show, project_id: @project_id, format: 'odt'
    assert_response :success
    assert_equal 'application/vnd.oasis.opendocument.text',
                 response.content_type
  end

  test 'export should respond to ODT format' do
    get :export, project_id: @project_id, format: 'odt'
    assert_response :success
    assert_equal 'application/vnd.oasis.opendocument.text',
                 response.content_type
  end
end
