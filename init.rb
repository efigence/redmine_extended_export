Redmine::Plugin.register :redmine_export_subtasks do
  name 'Redmine Export Subtasks plugin'
  author 'Jacek Grzybowski'
  description 'Export subtasks and related issues to xlsx, pdf, etc.'
  version '0.0.1'
  url 'https://github.com/efigence/redmine_export_subtasks'
  author_url 'http://efigence.com'
end

require 'redmine_export_subtasks/hooks/show_issue_hook'

ActionDispatch::Callbacks.to_prepare do
  IssueQuery.send(:include, RedmineExportSubtasks::Patches::IssueQueryPatch)
end
