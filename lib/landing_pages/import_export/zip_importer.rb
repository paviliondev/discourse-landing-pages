# frozen_string_literal: true

class LandingPages::ZipImporter < ThemeStore::ZipImporter
  attr_reader :temp_folder

  def initialize(filename, original_filename, temp_folder: '/')
    @temp_folder = temp_folder
    @filename = filename
    @original_filename = original_filename
  end
end
