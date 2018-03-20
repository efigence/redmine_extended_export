module Redmine
  module Export
    module ODT
      module WikiOdtHelper
        def wiki_pages_to_odt(pages, project)
          doc = Html2Odt::Document.new

          doc.image_location_mapping = image_location_mapping_proc(pages.map(&:attachments).flatten)

          doc.html = cleanup_html(html_for_page_hierarchy(pages.group_by(&:parent_id)))
          doc.base_uri = project_wiki_index_url(project)

          doc.title = project.name
          doc.author = User.current.name

          doc.data
        end

        def wiki_page_to_odt(page, project)
          doc = Html2Odt::Document.new

          doc.image_location_mapping = image_location_mapping_proc(page.attachments)
          doc.base_uri = project_wiki_page_url(project, page)

          doc.author = User.current.name
          doc.title = "#{project.name} - #{page.title}"

          doc.html = cleanup_html(html_for_page_hierarchy(nil => [page]))

          doc.data
        end

        protected

        def html_for_page_hierarchy(pages, node = nil, level = 0)
          return "" if pages[node].blank?

          html = ""

          pages[node].each do |page|
            html += "<hr/>\n" unless level == 0 && page == pages[node].first

            html += textilizable(page.content, :text,
                                               :only_path => false,
                                               :edit_section_links => false,
                                               :headings => false)

            html += html_for_page_hierarchy(pages, page.id, level + 1)
          end

          html
        end

        def cleanup_html(html)
          # Strip {{toc}} tags
          #
          # The links generated within the toc-pseudo-macro will not work inside
          # the ODT, so let's remove it..
          html = html.gsub(/<p>\{\{([<>]?)toc.*?\}\}<\/p>/i, '')


          # Cleanup {{collapse}} macro output
          #
          # The collapse macro is generating the following (simplified) markup:
          #
          # <p>
          #   <a class="collapsible collapsed">Open link</a>
          #   <a class="collapsible">Close link</a>
          #   <div class="collapsed-text">Content</div>
          # </p>
          #
          # An HTML parser (like Nokogiri or any browser) will create the
          # following DOM
          #
          # <p>
          #   <a class="collapsible collapsed">Open link</a>
          #   <a class="collapsible">Close link</a>
          # </p>
          # <div class="collapsed-text">Content</div>
          # <p/>
          #
          # So we're trying to remove the first p, containing the links, and
          # we're replacing the div.collapsed-text with its content. The
          # remaining p is difficult to target (or does not seem to be created
          # in Nokogiri), so we're leaving that one alone.
          #
          # In a previous version, we were only removing the links themselves,
          # but this lead to errors in html2odt's own HTML cleanup (elements,
          # that needed fixing were not found).
          doc = Nokogiri::HTML::DocumentFragment.parse(html)

          doc.css(".collapsible.collapsed").each do |collapsed_links|
            collapsed_links.parent.remove
          end

          doc.css(".collapsed-text").each do |collapsed_text|
            collapsed_text.replace collapsed_text.children
          end

          html = doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)

          html
        end

        def image_location_mapping_proc(attachments)
          lambda do |src|
            # See if src maps to local URL which happens to be an attachment of
            # this wiki page

            if src =~ /\Ahttps?:\/\//
              # Ignore URLs pointing to other hosts

              src_uri = URI.parse(src) rescue nil
              next unless src_uri

              src_base_url = "#{src_uri.scheme}://#{src_uri.host}"
              if src_uri.default_port != src_uri.port
                src_base_url += ":#{src_uri.port}"
              end

              next if request.base_url != src_base_url
            else
              # Ignore URLs with protocols != http(s)
              next if src.include? "://"
            end

            # Include public images
            #
            public_path = File.join(Rails.public_path, src)

            # but make sure, that we're not vulnerable to directory traversal attacks
            #
            # File.realpath accesses file system and raises Errno::ENOENT if file
            # does not exist
            valid_path = File.realpath(public_path).starts_with?(Rails.public_path.to_s) rescue false
            next public_path if valid_path and File.readable?(public_path)

            # Include attached images
            # because of /redmine
            uri = URI.parse(src_uri.to_s)
            src = uri.path.gsub("/redmine", "") rescue nil
            path = Rails.application.routes.recognize_path(src)
            next if path.blank?
            next if path[:controller] != "attachments"
            next if path[:id].blank?

            attachment = attachments.find { |a| a.to_param == path[:id] }
            if path[:action] == "thumbnail" and path[:size].present?
              return attachment.thumbnail(size: path[:size])
            end
            if path[:action] == "download"
              return attachment.diskfile
            end
          end
        end
      end
    end
  end
end
