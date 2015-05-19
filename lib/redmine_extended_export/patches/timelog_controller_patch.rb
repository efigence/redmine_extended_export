require_dependency 'timelog_controller'

module RedmineExtendedExport
  module Patches
    module TimelogControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :index, :extended_formats
        end
      end

      module InstanceMethods
        def index_with_extended_formats
          if %w(pdf xlsx).include? params[:format]
            render_extended_format
          else
            index_without_extended_formats
          end
        end

        def render_extended_format
          @query = TimeEntryQuery.build_from_params(params, :project => @project, :name => '_')

          sort_init(@query.sort_criteria.empty? ? [['spent_on', 'desc']] : @query.sort_criteria)
          sort_update(@query.sortable_columns)
          scope = time_entry_scope(:order => sort_clause).
            includes(:project, :user, :issue).
            preload(:issue => [:project, :tracker, :status, :assigned_to, :priority])

          respond_to do |format|
            format.xlsx {
              @entries = scope.to_a
              send_data(query_to_xlsx(@entries, @query, params), :type => 'application/xlsx', :filename => 'timelog.xlsx')
            }

            format.pdf  {
              @entries = scope.to_a
              send_file_headers! :type => 'application/pdf', :filename => 'timelog.pdf'
            }
          end
        end
      end
    end
  end
end
