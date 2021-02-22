# frozen_string_literal: true

if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start do
    root "plugins/discourse-landing-pages"
    track_files "plugins/discourse-landing-pages/**/*.rb"
    add_filter { |src| src.filename =~ /(\/spec\/|\/gems\/|plugin\.rb)/ }
  end
end

require 'rails_helper'