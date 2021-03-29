class LandingPages::Updater
  include HasErrors
  
  attr_reader :handler
  attr_accessor :updated
    
  def initialize(type, handler)
    @type = type
    @handler = handler
    @updated = {
      scripts: [],
      footer: false,
      header: false,
      menus: [],
      assets: [],
      pages: []
    }
  end
  
  def update(path="")
    global_data = read_file(path + "pages.json")
    asset_data = read_file(path + "assets.json")
    page_data = read_file(path + "page.json")

    return if errors.any?

    if global_data.present?
      update_global(
        scripts: global_data['scripts'],
        header: global_data['header'],
        footer: global_data['footer'],
        menus: global_data['menus']
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
        parent: page_data["parent"],
        theme: page_data["theme"],
        groups: page_data["groups"],
        menu: page_data["menu"],
        assets: page_data["assets"]
      )
    end
  end
  
  def update_page(params)
    params[:remote] = @handler.url if @type == :git

    params = LandingPages::Page.find_discourse_objects(params)
    page = nil

    if params[:parent] && parent_page = LandingPages::Page.find_by("path", params[:parent])
      page = LandingPages::Page.find_child_page(params[:parent])
      params[:parent_id] = parent_page.id
    elsif params[:path]
      page = LandingPages::Page.find_by("path", params[:path])
    end
    
    if page.blank?
      page = LandingPages::Page.create(params)
    else
      page.set(params)
      page.save
    end
    
    if page.errors.any?
      add_errors_from(page)
    else
      @updated[:pages].push(page.name)
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
        @updated[:assets].push(asset.name)
      end
    end
  end
  
  def update_global(params)
    updated_scripts = []
    updated_menus = []
    updated_footer = false
    updated_header = false
    
    global_params = params.slice(:scripts, :header, :footer)
    global = LandingPages::Global.new(global_params)
    
    if global.save
      updated_scripts = global.scripts.present?
      updated_footer = global.header.present?
      updated_header = global.footer.present?
    end
    
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
          updated_menus.push(menu.name)
        end
      end
    end 
    
    unless errors.any?
      @updated[:scripts] = updated_scripts
      @updated[:menus] = updated_menus
      @updated[:header] = updated_header
      @updated[:footer] = updated_footer
    end
  end
  
  def read_file(path)
    file = @handler[path]
    return unless file.present?
    
    begin
      JSON.parse(file)
    rescue TypeError, JSON::ParserError => error
      add_error(I18n.t("landing_pages.error.import_json", path: path, error: error))
    end
  end
end