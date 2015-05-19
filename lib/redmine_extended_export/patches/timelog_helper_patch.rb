require_dependency 'timelog_helper'

module RedmineExtendedExport
  module Patches
    module TimelogHelperPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          include Redmine::Export::PDF::TimelogPdfHelper
        end
      end

      module InstanceMethods
      end
    end
  end
end
