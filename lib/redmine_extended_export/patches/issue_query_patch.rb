require_dependency 'issue_query'

module RedmineExtendedExport
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          available_columns << QueryColumn.new(:comments, :inline => false)
        end
      end

      module InstanceMethods
        def statement
          if filters.key? :issue_ids
            ids_to_string = filters[:issue_ids][:values].join(', ')
            ids_to_string.present? ? "#{Issue.table_name}.id IN (#{ids_to_string})" : "1=0"
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
