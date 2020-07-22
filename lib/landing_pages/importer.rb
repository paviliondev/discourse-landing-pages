# frozen_string_literal: true

class LandingPages::Importer  
  attr_reader :type,
              :bundle
  
  attr_accessor :handler,
                :report
  
  def initialize(type, bundle: nil)
    @type = type
    @bundle = bundle if bundle
  end
  
  def perform!
    import!
    update! if report[:errors].blank?
    cleanup!
  end
  
  def import!
    if type == :zip && bundle.present?
      @handler = LandingPages::ZipImporter.new(
        bundle.tempfile.path,
        bundle.original_filename
      )
    elsif type == :git
      remote = LandingPages::Remote.get
      @handler = LandingPages::GitImporter.new(remote.url,
        private_key: remote.private_key,
        branch: remote.branch
      )
    end
    
    if @handler.blank?
      add_error(I18n.t("landing_pages.error.import_handler"))
    else
      begin
        @handler.import!
      rescue RemoteTheme::ImportError => e
        add_error(I18n.t("landing_pages.error.import_failed"))    
      end
    end
  end
  
  def files
    @handler.all_files
  end
  
  def update!    
    files.each do |path|
      if path.match? /page.json|menu.json/
        import_path = path.rpartition("/").first
        updated = update("#{import_path}/")
        
        if updated.blank?
          add_error(I18n.t("landing_pages.error.import_update_failed"))
        elsif updated.errors.any?
          add_error(updated_page.errors.full_messages.join(", "), name: updated.name)
        else
          import_complete(updated.name)
        end
      end
    end
  end
  
  def update(path="")    
    if @handler[path + "page.json"]
      update_page(path)
    elsif @handler[path + "menu.json"]
      update_menu(path)
    else
      nil
    end
  end
  
  def update_page(path)
    begin
      data = JSON.parse(@handler[path + "page.json"])
    rescue TypeError, JSON::ParserError
      add_error(I18n.t("landing_pages.error.import_page_json"))
    end
    
    return if report[:errors].any?
    
    params = {
      name: data["name"],
      path: data["path"],
      body: @handler[path + "body.html.erb"]
    }
    
    params[:remote] = @handler.url if type == :git
    
    if data["theme"].present?
      if theme = Theme.find_by(name: data["theme"])
        params[:theme_id] = theme.id
      end
    end
    
    if data["groups"].present?
      params[:group_ids] = []
      
      data["groups"].each do |group_name|
        if group = Group.find_by(name: group_name)
          params[:group_ids].push(group.id)
        end
      end
    end
        
    page = LandingPages::Page.find_by("path", params[:path])
        
    if page.blank?
      page = LandingPages::Page.create(params)
    else
      page.set(params)
      page.save
    end
    
    page
  end
  
  def update_menu(path)    
    begin
      data = JSON.parse(@handler[path + "menu.json"])
    rescue TypeError, JSON::ParserError
      add_error(I18n.t("landing_pages.error.import_menu_json"))
    end
    
    return if report[:errors].any?
    
    params = {
      name: data["name"],
      items: data["items"]
    }
        
    menu = LandingPages::Menu.find_by("name", params[:name])
        
    if menu.blank?
      menu = LandingPages::Menu.create(params)
    else
      menu.set(params)
      menu.save
    end
    
    menu
  end
  
  def cleanup!
    @handler.cleanup!
  end
  
  def report
    @report ||= { imported: [], errors: [] }
  end
  
  def add_error(message, page: nil)
    error = ""
    error += "#{page}: " if page.present?
    error += message
    report[:errors].push(error)
  end
  
  def import_complete(page)
    report[:imported].push(I18n.t("landing_pages.imported", page: page))
  end
end