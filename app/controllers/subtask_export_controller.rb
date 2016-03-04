class SubtaskExportController < ApplicationController
  unloadable

  include QueriesHelper

  before_action :find_issue
  before_action :set_query

  def subtasks
    descendant_ids = @issue.descendants.visible.pluck(:id)
    respond_with_data(descendant_ids, :lft)
  end

  def related
    related_ids = @issue.relations.
      select { |r| r.other_issue(@issue) && r.other_issue(@issue).visible? }.
      map    { |r| r.other_issue(@issue).id }

    respond_with_data(related_ids, :id)
  end

  private

  def respond_with_data(issue_ids, order)

    return head :not_acceptable if issue_ids.blank?

    @query.build_from_params_with_issue_ids(issue_ids)
    @query.filters[:issue_ids][:values] -= check_statuses if params[:format] != 'pdf'

    @limit = Setting.issues_export_limit.to_i

    @query.column_names = @query.available_inline_columns.map(&:name)
    if params[:format] != 'pdf'
      @query.column_names -= check_parameters
      unless @query.column_names.include?(:id)
        @query.column_names.unshift('id')
      end
    end

    @issue_count = @query.issue_count
    @issue_pages = Paginator.new @issue_count, @limit, params['page']
    @offset ||= @issue_pages.offset
    @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                            :order => order,
                            :offset => @offset,
                            :limit => @limit)
                            # binding.pry

    respond_to do |format|
      format.csv  { send_data(query_to_csv(@issues, @query, params), :type => 'text/csv; header=present', :filename => 'issues.csv') }
      format.xlsx { send_data(query_to_xlsx(@issues, @query, params), :type => 'application/xlsx', :filename => 'issues.xlsx') }
      format.pdf  { send_file_headers! :type => 'application/pdf', :filename => 'issues.pdf' }
    end

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue
    @issue = Issue.find(params[:id])
    @project = @issue.project
  end

  def set_query
    @query = IssueQuery.new
  end

  def check_parameters
    params_array = @query.available_inline_columns.map(&:name) - [:id]
    return params_array unless params[:columns]
    params_array.map { |parameter| parameter unless params[:columns].include?(parameter.to_s) }
  end

  def check_statuses
    output = []
    IssueStatus.all.each do |statuss|
      if params[:statuses] && params[:statuses].include?(statuss.name)
        output += Issue.where(status_id: statuss.id).map(&:id)
      end
    end
    output
  end
end
