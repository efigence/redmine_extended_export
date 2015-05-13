require File.expand_path('../../test_helper', __FILE__)

class IssueQueryTest < ActiveSupport::TestCase

  def setup
    @query = IssueQuery.new
  end

  test "issue_query class is extended with comments query_column" do
    assert IssueQuery.available_columns.detect { |s| s.name == :comments }
  end

  test "issue query responds to patched methods" do
    assert @query.respond_to?(:build_from_params_with_issue_ids)
    assert @query.respond_to?(:add_issue_ids_filter)
  end

  test "query responds with issues of passed issue ids" do
    ids = [1,2,5,6]
    @query.build_from_params_with_issue_ids(ids)
    string_ids = ids.join(', ')
    assert "#{Issue.table_name}.id IN (#{string_ids})", @query.statement
    assert ids, @query.issues.map(&:id)
  end

  test "query responds with empty array if no ids passed" do
    ids = []
    @query.build_from_params_with_issue_ids(ids)
    assert "1=0", @query.statement
    assert [], @query.issues
  end
end
