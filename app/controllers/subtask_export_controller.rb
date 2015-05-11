class SubtaskExportController < ApplicationController
  unloadable

  include SortHelper
  include QueriesHelper
  include ::Redmine::Export::PDF # TODO

  before_action :find_issue
  before_action :set_query

  def subtasks
    descendant_ids = @issue.descendants.visible.pluck(:id)

    @query.build_from_params(issue_ids: descendant_ids)

    sort_init [['lft', 'id', 'desc']]
    sort_update @query.sortable_columns
    @query.sort_criteria = sort_criteria.to_a

    case params[:format]
    when 'csv', 'pdf', 'xlsx'
      @limit = Setting.issues_export_limit.to_i
      if params[:columns] == 'all'
        @query.column_names = @query.available_inline_columns.map(&:name)
      end
    when 'atom'
      @limit = Setting.feeds_limit.to_i
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
      @query.column_names = %w(author)
    end

    @issue_count = @query.issue_count
    @issue_pages = Paginator.new @issue_count, @limit, params['page']
    @offset ||= @issue_pages.offset
    @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                            :order => sort_clause,
                            :offset => @offset,
                            :limit => @limit)
    @issue_count_by_group = @query.issue_count_by_group

    respond_to do |format|
      format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
      format.csv  { send_data(query_to_csv(@issues, @query, params), :type => 'text/csv; header=present', :filename => 'issues.csv') }
      format.pdf  { send_file_headers! :type => 'application/pdf', :filename => 'issues.pdf' }
      format.xlsx { send_data(query_to_xlsx(@issues, @query, params), :type => 'application/xlsx', :filename => 'issues.xlsx') }
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
