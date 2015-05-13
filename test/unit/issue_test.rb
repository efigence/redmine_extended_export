require File.expand_path('../../test_helper', __FILE__)

class IssueTest < ActiveSupport::TestCase

  def setup
    @issue = issues(:issues_nested_sub1)
  end

  test "issue responds to comments method" do
    assert @issue.respond_to?(:comments), "doesn't respond to comments"
    assert @issue.comments.is_a?(String), "not a string"
  end

  test "issue comments return existing note body" do
    note = @issue.journals.pluck(:notes).first
    assert @issue.comments.include?(note), "doesn't include existing note"
  end

  test "issue comments return empty string if no notes exist" do
    assert_equal "", issues(:root).comments, "not an empty string"
  end
end
