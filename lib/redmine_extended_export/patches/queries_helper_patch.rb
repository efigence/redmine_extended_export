require_dependency 'queries_helper'

module RedmineExtendedExport
  module Patches
    module QueriesHelperPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods
        def query_to_xlsx(items, query, options={})
          encoding = l(:general_csv_encoding)

          p = Axlsx::Package.new
          p.workbook.add_worksheet(:name => "issues") do |sheet|
            columns = (options[:columns] == 'all' ? query.available_inline_columns : query.inline_columns)
            query.available_block_columns.each do |column|
              if options[column.name].present?
                columns << column
              end
            end
            sheet.add_row columns.collect {|c| Redmine::CodesetUtil.from_utf8(c.caption.to_s, encoding) }

            items.each do |item|
              row = columns.collect {|c| Redmine::CodesetUtil.from_utf8(csv_content(c, item), encoding) }
              puts row.inspect
              sheet.add_row row, types: []
              sheet.add_hyperlink :location => issue_url(item.id), :ref => sheet.rows.last.cells.first
            end
          end

          p.to_stream.read
        end
      end
    end
  end
end
