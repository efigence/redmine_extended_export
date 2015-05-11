module RedmineExportSubtasks
  module Hooks
    class ShowIssueHook < Redmine::Hook::ViewListener
      render_on(:view_issues_show_details_bottom, :partial => 'issues/export_links', :layout => false)
    end
  end
end
