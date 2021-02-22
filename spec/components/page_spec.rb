require_relative '../plugin_helper'

describe LandingPages::Page do
  fab!(:theme) { Fabricate(:theme, name: 'Landing Theme') }
  fab!(:group) { Fabricate(:group, name: 'page_group') }

  let(:raw_page) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/page.json"
    ).read)
  }
  
  let(:raw_body) {
    File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/body.html.erb"
    ).read
  }

  before do
    @params = raw_page
    @params[:body] = raw_body
  end
  
  it "creates a page" do
    LandingPages::Page.create(@params)
    page = LandingPages::Page.find_by('name', raw_page['name'])
    
    expect(page.name).to eq("My Page")
    expect(page.path).to eq("my-page")
    expect(page.body).to eq(raw_body)
  end
  
  it "does not create page if params are missing a required attribute" do
    required_attr = LandingPages::Page.required_attrs.first
    @params[required_attr.to_sym] = nil
    page = LandingPages::Page.create(@params)
    
    expect(page.errors.full_messages.first).to eq(
      I18n.t("landing_pages.error.attr_required", attr: required_attr)
    )
  end
  
  it "creates a page with discourse attributes" do
    @params[:theme] = theme.name
    @params[:groups] = [group.name]
    LandingPages::Page.find_discourse_objects(@params)
    LandingPages::Page.create(@params)
    page = LandingPages::Page.find_by('name', raw_page['name'])
    
    expect(page.theme_id).to eq(theme.id)
    expect(page.group_ids).to eq([group.id])
  end
  
  it "does not save discourse attributes if the discourse objects don't exist" do
    theme.destroy
    
    @params[:theme] = theme.name
    LandingPages::Page.find_discourse_objects(@params)
    LandingPages::Page.create(@params)
    page = LandingPages::Page.find_by('name', raw_page['name'])
    
    expect(page.theme_id).to eq(nil)
  end
  
  it "creates a page with pages attributes" do
    @params[:remote] = 'https://github.com/paviliondev/pages-repo.git'
    @params[:assets] = ["animation"]

    LandingPages::Page.create(@params)
    page = LandingPages::Page.find_by('name', raw_page['name'])
    
    expect(page.remote).to eq('https://github.com/paviliondev/pages-repo.git')
    expect(page.assets).to eq(["animation"])
  end
  
  it "does not create a page with a duplicate path" do
    @params["path"] = "about"
    page = LandingPages::Page.create(@params)
    
    expect(page.errors.full_messages.first).to eq(
      I18n.t("landing_pages.error.path_exists")
    )
  end
  
  it "updates a page" do
    page = LandingPages::Page.create(@params)
    
    @params["name"] = "My new page"
    page.set(@params)
    page.save
    
    expect(page.name).to eq("My new page")
  end
  
  it "destroys a page" do
    page = LandingPages::Page.create(@params)
    LandingPages::Page.destroy(page.id)
    expect(LandingPages::Page.exists?(page.id)).to eq(false)
  end
  
  it "lists all pages" do
    LandingPages::Page.create(@params)
    
    second_page_params = @params.dup
    second_page_params['name'] = 'My second page'
    second_page_params['path'] = 'my-second-page'
    LandingPages::Page.create(second_page_params)
    
    all_pages = LandingPages::Page.all
    expect(all_pages.length).to eq(2)
    expect(all_pages.select { |p| p.path == 'my-page' }.length).to eq(1)
    expect(all_pages.select { |p| p.path == 'my-second-page' }.length).to eq(1)
  end
end