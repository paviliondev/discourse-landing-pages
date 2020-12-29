class LandingPages::Updater
  include HasErrors
  
  attr_reader :handler
  attr_accessor :updated
    
  def initialize(type, handler)
    @type = type
    @handler = handler
    @updated = []
  end
  
  def update(path="")
    pages_data = read_file(path + "/pages.json")
    asset_data = read_file(path + "/assets.json")
    page_data = read_file(path + "/page.json")
    
    return if errors.any?
    
    if pages_data.present?
      update_pages(
        scripts: pages_data['scripts'],
        header: pages_data['header'],
        footer: pages_data['footer'],
        menus: pages_data['menus']
      )
    end
    
    if asset_data.present?
      update_assets(
        register: asset_data['register']
      )
    end
    
    if page_data.present?
      update_page(
        name: page_data["name"],
        path: page_data["path"],
        body: @handler[path + "/body.html.erb"],
        theme: page_data["theme"],
        groups: page_data["groups"],
        menu: page_data["menu"],
        assets: page_data["assets"]
      )
    end
  end
  
  def update_page(params)
    params[:remote] = @handler.url if @type == :git
    
    if params[:theme].present?
      if theme = Theme.find_by(name: params[:theme])
        params[:theme_id] = theme.id
      end
    end
    
    if params[:groups].present?
      params[:group_ids] = []
      
      params[:groups].each do |group_name|
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
    
    if page.errors.any?
      add_errors_from(page)
    else
      @updated.push(page.name)
    end
  end
  
  def update_assets(params)    
    params[:register].each do |name, path|
      full_path = @handler.real_path(path)
      next unless full_path.present?
      
      asset = LandingPages::Asset.find_by("name", name)
      file = File.new(full_path)
      
      if asset.blank?
        asset = LandingPages::Asset.create(name: name, file: file)
      else
        asset.file = file
        asset.save
      end
            
      if asset.errors.any?
        add_errors_from(asset)
      else
        @updated.push(asset.name)
      end
    end
  end
  
  def update_pages(params)
    pages = LandingPages::Pages.new(params.slice(:scripts, :header, :footer))
    pages.save
    
    if params[:menus].present?
      params[:menus].each do |menu_data|
        menu_params = {
          name: menu_data["name"],
          items: menu_data["items"]
        }
        menu = LandingPages::Menu.find_by("name", menu_params[:name])
      
        if menu.blank?
          menu = LandingPages::Menu.create(menu_params)
        else
          menu.set(menu_params)
          menu.save
        end
        
        if menu.errors.any?
          add_errors_from(menu)
        else
          @updated.push(menu.name)
        end
      end
    end  
  end
  
  def read_file(path)
    file = @handler[path]
    return unless file.present?
    begin
      JSON.parse(file)
    rescue TypeError, JSON::ParserError => error
      add_error(I18n.t("landing_pages.error.import_json", path: path))
    end
  end
end