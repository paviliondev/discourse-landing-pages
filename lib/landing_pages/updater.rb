# frozen_string_literal: true
class LandingPages::Updater
  include HasErrors

  attr_reader :handler
  attr_accessor :updated

  def initialize(type, handler)
    @type = type
    @handler = handler
    @updated = { scripts: [], footer: false, header: false, menus: [], assets: [], pages: [] }
  end

  def update_page(data)
    data[:remote] = @handler.url if @type == :git

    data = LandingPages::Page.find_discourse_objects(data)
    page = nil

    if data[:parent] && parent_page = LandingPages::Page.find_by("path", data[:parent])
      page = LandingPages::Page.find_child_page(data[:parent])
      data[:parent_id] = parent_page.id
    elsif data[:path]
      page = LandingPages::Page.find_by("path", data[:path])
    end

    if page.blank?
      page = LandingPages::Page.create(data)
    else
      page.set(data)
      page.save
    end

    page.errors.any? ? add_errors_from(page) : @updated[:pages].push(page.name)
  end

  def update_assets(data)
    data[:register].each do |name, path|
      full_path = @handler.real_path(path)
      next if full_path.blank?

      asset = LandingPages::Asset.find_by("name", name)
      file = File.new(full_path)

      if asset.blank?
        asset = LandingPages::Asset.create(name: name, file: file)
      else
        asset.file = file
        asset.save
      end

      asset.errors.any? ? add_errors_from(asset) : @updated[:assets].push(asset.name)
    end
  end

  def update_global(data)
    updated_scripts = []
    updated_menus = []
    updated_footer = false
    updated_header = false

    global_data = data.slice(:scripts, :header, :footer)
    global = LandingPages::Global.new(global_data)

    if global.save
      updated_scripts = global.scripts.present?
      updated_footer = global.header.present?
      updated_header = global.footer.present?
    end

    if data[:menus].present?
      data[:menus].each do |menu_data|
        menu_data = { name: menu_data["name"], items: menu_data["items"] }
        menu = LandingPages::Menu.find_by("name", menu_data[:name])

        if menu.blank?
          menu = LandingPages::Menu.create(menu_data)
        else
          menu.set(menu_data)
          menu.save
        end

        menu.errors.any? ? add_errors_from(menu) : updated_menus.push(menu.name)
      end
    end

    if errors.none?
      @updated[:scripts] = updated_scripts
      @updated[:menus] = updated_menus
      @updated[:header] = updated_header
      @updated[:footer] = updated_footer
    end
  end
end
