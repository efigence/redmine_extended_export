require_dependency 'issue'

module RedmineExportSubtasks
  module Patches
    module IssuePatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods
        def comments(include_private=false)
          comments = self.journals.where('notes IS NOT NULL AND notes != ""')
          if !include_private
            comments = comments.where(private_notes: false )
          end
          result = []
          comments.each do |c|
            result << "#{c.id} - #{c.user} on #{c.created_on} wrote : \n\r #{c.notes}\n\r".gsub('"', "'")
          end
          result = result.join("\n\r")
          result
        end
      end
    end
  end
end
