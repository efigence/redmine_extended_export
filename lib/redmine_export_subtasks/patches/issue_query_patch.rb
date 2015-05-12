require_dependency 'issue_query'

module RedmineExportSubtasks
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods
        def statement
          if filters.key? :issue_ids
            issue_ids_str = filters[:issue_ids][:values].join(', ')
            return "#{Issue.table_name}.id IN (#{issue_ids_str})"
          else
            super
          end
        end

        def build_from_params_with_issue_ids(issue_ids)
          add_issue_ids_filter(issue_ids)
        end

        def add_issue_ids_filter(issue_ids)
          filters[:issue_ids] = {:values => issue_ids}
        end
      end
    end
  end
end
