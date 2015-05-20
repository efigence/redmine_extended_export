# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2015  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Redmine
  module Export
    module PDF
      module TimelogPdfHelper
         # Returns a PDF string of a list of issues
        def timelog_to_pdf(entries, project, query)
          pdf = ITCPDF.new(current_language, "L")
          title = query.new_record? ? l(:label_time_entry_plural) : query.name
          title = "#{project} - #{title}" if project
          pdf.set_title(title)
          pdf.alias_nb_pages
          pdf.footer_date = format_date(Date.today)
          pdf.set_auto_page_break(false)
          pdf.add_page("L")

          # Landscape A4 = 210 x 297 mm
          page_height   = pdf.get_page_height # 210
          page_width    = pdf.get_page_width  # 297
          left_margin   = pdf.get_original_margins['left'] # 10
          right_margin  = pdf.get_original_margins['right'] # 10
          bottom_margin = pdf.get_footer_margin
          row_height    = 4

          # column widths
          table_width = page_width - right_margin - left_margin
          col_width = []
          unless query.inline_columns.empty?
            col_width = calc_col_timelog_width(entries, query, table_width, pdf)
            table_width = col_width.inject(0, :+)
          end

          if table_width > 0 && query.has_column?(:comments)
            col_width = col_width.map {|w| w * (page_width - right_margin - left_margin) / table_width}
            table_width = col_width.inject(0, :+)
          end

          # title
          pdf.SetFontStyle('B',11)
          pdf.RDMCell(190,10, title)
          pdf.ln

          render_table_header(pdf, query, col_width, row_height, table_width)
          previous_group = false

          entries.each do |entry|

            # fetch row values
            col_values = fetch_row_values(entry, query, 0)

            # make new page if it doesn't fit on the current one
            base_y     = pdf.get_y
            max_height = get_time_entries_to_pdf_write_cells(pdf, col_values, col_width)
            space_left = page_height - base_y - bottom_margin
            if max_height > space_left
              pdf.add_page("L")
              render_table_header(pdf, query, col_width, row_height, table_width)
              base_y = pdf.get_y
            end

            # write the cells on page
            time_entries_to_pdf_write_cells(pdf, col_values, col_width, max_height)
            pdf.set_y(base_y + max_height)

            if query.has_column?(:comments) && entry.comments?
              pdf.set_x(10)
              pdf.set_auto_page_break(true, bottom_margin)
              pdf.RDMwriteHTMLCell(0, 5, 10, '', entry.description.to_s, nil, "LRBT")
              pdf.set_auto_page_break(false)
            end
          end

          if entries.size == Setting.plugin_redmine_extended_export['timelog_export_limit']
            pdf.SetFontStyle('B',10)
            pdf.RDMCell(0, row_height, '...')
          end
          pdf.output
        end

        # calculate columns width
        def calc_col_timelog_width(entries, query, table_width, pdf)
          # calculate statistics
          #  by captions
          pdf.SetFontStyle('B',8)
          margins = pdf.get_margins
          col_padding = margins['cell']
          col_width_min = query.inline_columns.map {|v| pdf.get_string_width(v.caption) + col_padding}
          col_width_max = Array.new(col_width_min)
          col_width_avg = Array.new(col_width_min)
          col_min = pdf.get_string_width('OO') + col_padding * 2
          if table_width > col_min * col_width_avg.length
            table_width -= col_min * col_width_avg.length
          else
            col_min = pdf.get_string_width('O') + col_padding * 2
            if table_width > col_min * col_width_avg.length
              table_width -= col_min * col_width_avg.length
            else
              ratio = table_width / col_width_avg.inject(0, :+)
              return col_width = col_width_avg.map {|w| w * ratio}
            end
          end
          word_width_max = query.inline_columns.map {|c|
            n = 10
            c.caption.split.each {|w|
              x = pdf.get_string_width(w) + col_padding
              n = x if n < x
            }
            n
          }

          # by properties of entries
          pdf.SetFontStyle('',8)
          k = 1
          entries.each do |entry|
            k += 1
            values = fetch_row_values(entry, query, 0)
            values.each_with_index {|v,i|
              n = pdf.get_string_width(v) + col_padding * 2
              col_width_max[i] = n if col_width_max[i] < n
              col_width_min[i] = n if col_width_min[i] > n
              col_width_avg[i] += n
              v.split.each {|w|
                x = pdf.get_string_width(w) + col_padding
                word_width_max[i] = x if word_width_max[i] < x
              }
            }
          end

          col_width_avg.map! {|x| x / k}

          # calculate columns width
          ratio = table_width / col_width_avg.inject(0, :+)
          col_width = col_width_avg.map {|w| w * ratio}

          # correct max word width if too many columns
          ratio = table_width / word_width_max.inject(0, :+)
          word_width_max.map! {|v| v * ratio} if ratio < 1

          # correct and lock width of some columns
          done = 1
          col_fix = []
          col_width.each_with_index do |w,i|
            if w > col_width_max[i]
              col_width[i] = col_width_max[i]
              col_fix[i] = 1
              done = 0
            elsif w < word_width_max[i]
              col_width[i] = word_width_max[i]
              col_fix[i] = 1
              done = 0
            else
              col_fix[i] = 0
            end
          end

          # iterate while need to correct and lock coluns width
          while done == 0
            # calculate free & locked columns width
            done = 1
            ratio = table_width / col_width.inject(0, :+)

            # correct columns width
            col_width.each_with_index do |w,i|
              if col_fix[i] == 0
                col_width[i] = w * ratio

                # check if column width less then max word width
                if col_width[i] < word_width_max[i]
                  col_width[i] = word_width_max[i]
                  col_fix[i] = 1
                  done = 0
                elsif col_width[i] > col_width_max[i]
                  col_width[i] = col_width_max[i]
                  col_fix[i] = 1
                  done = 0
                end
              end
            end
          end

          ratio = table_width / col_width.inject(0, :+)
          col_width.map! {|v| v * ratio + col_min}
          col_width
        end

        def render_table_header(pdf, query, col_width, row_height, table_width)
          # headers
          pdf.SetFontStyle('B',8)
          pdf.set_fill_color(230, 230, 230)

          base_x     = pdf.get_x
          base_y     = pdf.get_y
          max_height = get_time_entries_to_pdf_write_cells(pdf, query.inline_columns, col_width, true)

          # write the cells on page
          time_entries_to_pdf_write_cells(pdf, query.inline_columns, col_width, max_height, true)
          pdf.set_xy(base_x, base_y + max_height)

          # rows
          pdf.SetFontStyle('',8)
          pdf.set_fill_color(255, 255, 255)
        end

        # returns the maximum height of MultiCells
        def get_time_entries_to_pdf_write_cells(pdf, col_values, col_widths, head=false)
          heights = []
          col_values.each_with_index do |column, i|
            heights << pdf.get_string_height(col_widths[i], head ? column.caption : column)
          end
          return heights.max
        end

        # Renders MultiCells and returns the maximum height used
        def time_entries_to_pdf_write_cells(pdf, col_values, col_widths, row_height, head=false)
          col_values.each_with_index do |column, i|
            pdf.RDMMultiCell(col_widths[i], row_height, head ? column.caption : column.strip, 1, '', 1, 0)
          end
        end
      end
    end
  end
end
