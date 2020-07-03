# frozen_string_literal: true

require_dependency 'compression/engine'

class LandingPages::ImportError < StandardError; end

class LandingPages::PageImporter

  attr_reader :url

  def initialize(filename, original_filename)
    @temp_folder = "#{Pathname.new(Dir.tmpdir).realpath}/landing_page_#{SecureRandom.hex}"
    @filename = filename
    @original_filename = original_filename
  end

  def unzip!
    FileUtils.mkdir(@temp_folder)
    
    begin
      available_size = 1000
      Compression::Engine.engine_for(@original_filename).tap do |engine|
        engine.decompress(@temp_folder, @filename, available_size)
        engine.strip_directory(@temp_folder, @temp_folder, relative: true)
      end
    rescue RuntimeError
      raise LandingPages::ImportError, I18n.t("themes.import_error.unpack_failed")
    rescue Compression::Zip::ExtractFailed
      raise LandingPages::ImportError, I18n.t("themes.import_error.file_too_big")
    end
  end
  
  def [](value)
    fullpath = real_path(value)
    return nil unless fullpath
    File.read(fullpath)
  end
  
  def real_path(relative)
    fullpath = "#{@temp_folder}/#{relative}"
    return nil unless File.exist?(fullpath)

    fullpath = Pathname.new(fullpath).realpath.to_s

    if fullpath && fullpath.start_with?(@temp_folder)
      fullpath
    else
      nil
    end
  end

  def cleanup!
    FileUtils.rm_rf(@temp_folder)
  end
end
