require_dependency 'issues_controller'

module RedmineExtendedExport
  module Patches
    module IssuesControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :index, :xlsx
        end
      end

      module InstanceMethods
        def index_with_xlsx
          if params[:format] == 'xlsx'
            respond_with_xlsx
          else
            index_without_xlsx
          end
        end

        def respond_with_xlsx
          retrieve_query
          sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
          sort_update(@query.sortable_columns)
          @query.sort_criteria = sort_criteria.to_a

          @limit = Setting.issues_export_limit.to_i
          if params[:columns] == 'all'
            @query.column_names = @query.available_inline_columns.map(&:name)
          end

          @issue_count = @query.issue_count
          @issue_pages = Redmine::Pagination::Paginator.new @issue_count, @limit, params['page']
          @offset ||= @issue_pages.offset
          @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                                  :order => sort_clause,
                                  :offset => @offset,
                                  :limit => @limit)
          @issue_count_by_group = @query.issue_count_by_group

          respond_to do |format|
            format.xlsx { send_data(query_to_xlsx(@issues, @query, params), :type => 'application/xlsx', :filename => 'issues.xlsx') }
          end
        rescue ActiveRecord::RecordNotFound
          render_404
        end
      end
    end
  end
end
