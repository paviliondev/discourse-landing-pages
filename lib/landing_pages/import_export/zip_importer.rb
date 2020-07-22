# frozen_string_literal: true

class LandingPages::ZipImporter < ThemeStore::ZipImporter
  attr_reader :temp_folder
  
  def initialize(filename, original_filename)
    @temp_folder = "#{Pathname.new(Dir.tmpdir).realpath}/landing_page_#{SecureRandom.hex}"
    @filename = filename
    @original_filename = original_filename
  end
end
