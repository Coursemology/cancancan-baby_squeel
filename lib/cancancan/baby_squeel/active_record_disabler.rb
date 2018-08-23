# frozen_string_literal: true
class CanCanCan::BabySqueel::ActiveRecordDisabler
  ::CanCan::ModelAdapters::ActiveRecord4Adapter.class_eval do
    def self.for_class?(_)
      false
    end
  end
  if defined?(::CanCan::ModelAdapters::ActiveRecord5Adapter)
    ::CanCan::ModelAdapters::ActiveRecord5Adapter.class_eval do
      def self.for_class?(_)
        false
      end
    end
  end
end
