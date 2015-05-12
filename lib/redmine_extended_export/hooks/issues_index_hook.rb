module RedmineExtendedExport
  module Hooks
    class IssuesIndexHook < Redmine::Hook::ViewListener
      render_on(:view_issues_index_bottom, :partial => 'issues/index_csv', :layout => false)
    end
  end
end
