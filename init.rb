# encoding: utf-8

Redmine::Plugin.register :redmine_extended_export do
  name 'Redmine Extended Export plugin'
  author 'Rafał Lisowski, Jacek Grzybowski'
  description 'Export issues to xlsx, export subtasks and related issues to xlsx, pdf, etc.'
  version '0.0.1'
  url 'https://github.com/efigence/redmine_extended_export'
  author_url 'http://efigence.com'
end

ActionDispatch::Callbacks.to_prepare do
  require_relative 'config/initializers/mime'
  require 'redmine_extended_export/hooks/show_issue_hook'
  require 'redmine_extended_export/hooks/issues_index_hook'

  IssueQuery.send(:include, RedmineExtendedExport::Patches::IssueQueryPatch)
  QueriesHelper.send(:include, RedmineExtendedExport::Patches::QueriesHelperPatch)
  Issue.send(:include, RedmineExtendedExport::Patches::IssuePatch)
  IssuesController.send(:include, RedmineExtendedExport::Patches::IssuesControllerPatch)
end
