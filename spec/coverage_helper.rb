# frozen_string_literal: true

if ENV['CI']
  require 'coveralls'
  Coveralls.wear!('rails')
end
