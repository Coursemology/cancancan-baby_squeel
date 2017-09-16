# frozen_string_literal: true
class CanCanCan::BabySqueel::ActiveRecordDisabler
  ::CanCan::ModelAdapters::ActiveRecord4Adapter.class_eval do
    def self.for_class?(_)
      false
    end
  end
end
