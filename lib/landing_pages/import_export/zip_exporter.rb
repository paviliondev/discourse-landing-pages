# frozen_string_literal: true

class LandingPages::ZipExporter < ThemeStore::ZipExporter
  def initialize(page)
    @page = page
    @temp_folder = "#{Pathname.new(Dir.tmpdir).realpath}/landing_page_#{SecureRandom.hex}"
    @export_name = @page.name.downcase.gsub(/[^0-9a-z.\-]/, '-')
    @export_name = "discourse-#{@export_name}" unless @export_name.starts_with?("discourse")
  end

  def export_to_folder
    destination_folder = File.join(@temp_folder, @export_name)
    FileUtils.mkdir_p(destination_folder)
    
    about = {}
    
    LandingPages::Page.about_attrs.each do |attr|
      value = @page.send(attr)
      
      next unless value.present?
      
      if attr === "theme_id"
        if theme = Theme.find_by(id: value)
          value = theme.name
        else
          value = nil
        end
      end
      
      if attr === "group_ids"
        value = value.reduce do |result, group_id|
          if group = Group.find_by(id: group_id)
            result.push(group.name)
          end
        end
      end
      
      about[attr] = value if value.present?
    end
    
    File.write(File.join(destination_folder, "page.json"), JSON.pretty_generate(about))
    
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
  
  def filename(attr)
    name = attr
    
    ext = {
      body: '.html.erb'
    }[attr.to_sym]
    
    name += ext if ext
    name
  end
end