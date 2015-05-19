module RedmineExtendedExport
  module Hooks
    class TimelogIndexHook < Redmine::Hook::ViewListener
      render_on(:view_layouts_base_html_head, :partial => 'timelog/export_extension', :layout => false)
    end
  end
end
