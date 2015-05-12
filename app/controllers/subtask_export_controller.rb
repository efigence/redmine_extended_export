class SubtaskExportController < ApplicationController
  unloadable

  include QueriesHelper

  before_action :find_issue
  before_action :set_query

  def subtasks
    descendant_ids = @issue.descendants.visible.pluck(:id)

    @query.build_from_params_with_issue_ids(descendant_ids)

    @limit = Setting.issues_export_limit.to_i
    @query.column_names = @query.available_inline_columns.map(&:name)

    @issue_count = @query.issue_count
    @issue_pages = Paginator.new @issue_count, @limit, params['page']
    @offset ||= @issue_pages.offset
    @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                            :order => :lft,
                            :offset => @offset,
                            :limit => @limit)

    respond_to do |format|
      format.csv  { send_data(query_to_csv(@issues, @query, params), :type => 'text/csv; header=present', :filename => 'issues.csv') }
      format.xlsx { send_data(query_to_xlsx(@issues, @query, params), :type => 'application/xlsx', :filename => 'issues.xlsx') }
      format.pdf  { send_file_headers! :type => 'application/pdf', :filename => 'issues.pdf' }
    end

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def related
    # TODO
  end

  private

  def find_issue
    @issue = Issue.find(params[:id])
    @project = @issue.project
  end

  def set_query
    @query = IssueQuery.new
  end
end
