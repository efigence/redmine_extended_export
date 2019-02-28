module RedmineExtendedExport
  module Hooks
    class WikiShowHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_content, partial: 'wiki/export_extension',
                                            layout: false
    end
  end
end
