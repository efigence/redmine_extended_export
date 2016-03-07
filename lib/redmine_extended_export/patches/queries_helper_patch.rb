require_dependency 'queries_helper'

module RedmineExtendedExport
  module Patches
    module QueriesHelperPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :query_to_csv, :lp
        end
      end

      module InstanceMethods
        def query_to_xlsx(items, query, options={})
          encoding = l(:general_csv_encoding)

          p = Axlsx::Package.new
          p.workbook.add_worksheet(:name => "issues") do |sheet|
            columns = (options[:columns] == 'all' ? query.available_inline_columns : ['L.p.'] + query.inline_columns)
            query.available_block_columns.each do |column|
              if options[column.name].present?
                columns << column
              end
            end
            sheet.add_row columns.collect {|c| Redmine::CodesetUtil.from_utf8((c.try(:caption) || c).to_s, encoding) }

            items.each.with_index do |item, index|
              row = [index + 1] + columns[1..-1].collect {|c| Redmine::CodesetUtil.from_utf8(csv_content(c, item), encoding) }
              sheet.add_row row, types: []
              sheet.add_hyperlink :location => issue_url(item.id), :ref => sheet.rows.last.cells.first
            end
          end

          p.to_stream.read
        end

        def query_to_csv_with_lp(items, query, options={})
          encoding = l(:general_csv_encoding)
          columns = (options[:columns] == 'all' ? query.available_inline_columns : ['L.p.'] + query.inline_columns)

          query.available_block_columns.each do |column|
            if options[column.name].present?
              columns << column
            end
          end

          export = CSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
            # csv header fields
            csv << columns.collect {|c| Redmine::CodesetUtil.from_utf8((c.try(:caption) || c).to_s, encoding) }
            # csv lines
            items.each.with_index do |item, index|
              csv << [index + 1] + columns[1..-1].collect {|c| Redmine::CodesetUtil.from_utf8(csv_content(c, item), encoding) }
            end
          end
          export
        end
      end
    end
  end
end
