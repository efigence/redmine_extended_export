require_dependency 'issues_controller'

module RedmineExtendedExport
  module Patches
    module IssuesControllerPatch
      include SortHelper

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :index, :csv
          alias_method_chain :index, :xlsx
        end
      end

      module InstanceMethods
        def index_with_csv
          if params[:format] == 'csv'
            respond_with_xlsx_or_csv
          else
            index_without_csv
          end
        end

        def index_with_xlsx
          if params[:format] == 'xlsx'
            respond_with_xlsx_or_csv
          else
            index_without_xlsx
          end
        end

        def respond_with_xlsx_or_csv
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
          @issues = @query.issues(include: %i[assigned_to tracker priority category fixed_version],
                                  order: sort_clause, offset: @offset, limit: @limit)
          @issue_count_by_group = @query.issue_count_by_group

          respond_to do |format|
            format.csv  { send_data(query_to_csv(@issues, @query, params), :type => 'text/csv; header=present', :filename => 'issues.csv') }
            format.xlsx { send_data(query_to_xlsx(@issues, @query, params), :type => 'application/xlsx', :filename => 'issues.xlsx') }
          end
        rescue ActiveRecord::RecordNotFound
          render_404
        end
      end
    end
  end
end
