# frozen_string_literal: true

require_dependency 'compression/zip'

class LandingPages::PageExporter

  def initialize(page)
    @page = page
    @temp_folder = "#{Pathname.new(Dir.tmpdir).realpath}/landing_page_#{SecureRandom.hex}"
    @export_name = @page.name.downcase.gsub(/[^0-9a-z.\-]/, '-')
    @export_name = "discourse-#{@export_name}" unless @export_name.starts_with?("discourse")
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
    
    meta = {
      id: @page.id
    }
    
    LandingPages::Page.meta_attrs.each do |attr|
      value = @page.send(attr)
      meta[attr] = value if value.present?
    end
    
    File.write(File.join(destination_folder, "meta.json"), JSON.pretty_generate(meta))
    
    LandingPages::Page.file_attrs.each do |attr|
      if (value = @page.try(attr)).present?
        pathname = Pathname.new(File.join(destination_folder, filename(attr)))
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
  
  def filename(attr)
    name = attr
    
    ext = {
      body: '.html.erb'
    }[attr.to_sym]
    
    name += ext if ext
    name
  end
end