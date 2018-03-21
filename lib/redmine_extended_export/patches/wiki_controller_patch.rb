require_dependency 'wiki_controller'

module RedmineExtendedExport
  module Patches
    module WikiControllerPatch
      extend ActiveSupport::Concern

      included do
        alias_method_chain :show, :odt
        alias_method_chain :export, :odt
      end

      def show_with_odt
        if User.current.allowed_to?(:export_wiki_pages, @project) &&
           params[:format] == 'odt'
         send_file_headers! :type => 'application/vnd.oasis.opendocument.text',
                            :filename => "#{@page.title}.odt"
         render inline: "<%= raw wiki_page_to_odt(@page, @project) %>"
        else
          show_without_odt
        end
      end

      def export_with_odt
        if params[:format] == 'odt'
          @pages = @wiki.pages.order('title')
                        .includes(:content, attachments: :author).to_a
          send_file_headers! :type => 'application/vnd.oasis.opendocument.text',
                             :filename => "#{@project.identifier}.odt"
          render inline: "<%= raw wiki_pages_to_odt(@pages, @project) %>"
        else
          export_without_odt
        end
      end
    end
  end
end
