# frozen_string_literal: true

require_dependency 'compression/zip'

class LandingPages::PageExporter

  def initialize(page)
    @page = page
    @temp_folder = "#{Pathname.new(Dir.tmpdir).realpath}/landing_page_#{SecureRandom.hex}"
    @export_name = @page.name.downcase.gsub(/[^0-9a-z.\-]/, '-')
    @export_name = "discourse-#{@export_name}" unless @export_name.starts_with?("discourse")
  end

  def export_name
    @export_name
  end

  def package_filename
    export_package
  end

  def cleanup!
    FileUtils.rm_rf(@temp_folder)
  end

  def export_to_folder
    destination_folder = File.join(@temp_folder, @export_name)
    FileUtils.mkdir_p(destination_folder)
    
    File.write(
      File.join(destination_folder, "about.json"),
      JSON.pretty_generate(
        name: @page.name,
        path: @page.path,
        theme_id: @page.theme_id
      )
    )
    
    @page.meta_attrs.each do |attr|
      if (value = @page.try(attr)).present?
        pathname = Pathname.new(File.join(destination_folder, path))
        folder_path = pathname.parent.cleanpath
        pathname.parent.mkpath
        path = pathname.realdirpath
        File.write(path, value)
      end
    end

    @temp_folder
  end

  private

  def export_package
    export_to_folder

    Compression::Zip.new.compress(@temp_folder, @export_name)
  end
end