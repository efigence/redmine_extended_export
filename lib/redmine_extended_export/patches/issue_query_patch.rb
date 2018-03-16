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

        # Returns the issue count by group or nil if query is not grouped
        def issue_count_by_group
          r = nil
          if grouped?
            begin
              # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
              r = Issue.visible.
                joins(:status, :project).
                joins(history_join_clause).
                where(statement).
                joins(joins_for_order_statement(group_by_statement)).
                group(group_by_statement).
                count
            rescue ActiveRecord::RecordNotFound
              r = {nil => issue_count}
            end
            c = group_by_column
            if c.is_a?(QueryCustomFieldColumn)
              r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
            end
            r
          end
        end
      end
    end
  end
end
