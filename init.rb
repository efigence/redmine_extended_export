Redmine::Plugin.register :redmine_export_subtasks do
  # TODO
  name 'Redmine Export Subtasks plugin'
  author 'Jacek Grzybowski'
  description 'Export subtasks and related issues to xlsx, pdf, etc.'
  version '0.0.1'
  url 'https://github.com/efigence/redmine_export_subtasks'
  author_url 'http://efigence.com'
end



ActionDispatch::Callbacks.to_prepare do
  require_relative 'config/initializers/mime'
  require 'redmine_export_subtasks/hooks/show_issue_hook'
  require 'redmine_export_subtasks/hooks/issues_index_hook'

  IssueQuery.send(:include, RedmineExportSubtasks::Patches::IssueQueryPatch)
  QueriesHelper.send(:include, RedmineExportSubtasks::Patches::QueriesHelperPatch)
  Issue.send(:include, RedmineExportSubtasks::Patches::IssuePatch)
  IssuesController.send(:include, RedmineExportSubtasks::Patches::IssuesControllerPatch)
end
