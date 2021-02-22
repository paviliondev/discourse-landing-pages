require_relative '../plugin_helper'

describe LandingPages::Updater do
  let(:raw_remote) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/remote.json"
    ).read)
  }
  let(:raw_global) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/pages.json"
    ).read)
  }
  let(:raw_assets) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/assets.json"
    ).read)
  }
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
  let(:raw_page_2) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/page_2/page.json"
    ).read)
  }
  let(:raw_body_2) {
    File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/page_2/body.html.erb"
    ).read
  }
  
  before do
    LandingPages::Remote.update(raw_remote)
    remote = LandingPages::Remote.get
    temp_folder_path = "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures"
    temp_folder = Pathname.new(temp_folder_path).realpath.to_s
    handler = LandingPages::GitImporter.new(remote.url,
      private_key: remote.private_key,
      branch: remote.branch,
      temp_folder: temp_folder
    )
    @updater = LandingPages::Updater.new(:git, handler)
  end
  
  it "updates globals" do
    @updater.update
    
    global = LandingPages::Global.find
    expect(global.scripts).to eq(raw_global['scripts'])
    expect(global.footer).to eq(raw_global['footer'])
    expect(global.header).to eq(raw_global['header'])
  end
  
  it "updates assets" do
    @updater.update
    
    assets = LandingPages::Asset.all
    expect(assets.length).to eq(2)
    expect(assets.first.name).to eq(raw_assets['register'].keys.first)
    expect(assets.second.name).to eq(raw_assets['register'].keys.second)
  end
  
  it "updates pages" do
    @updater.update
    
    page = LandingPages::Page.find_by('name', raw_page['name'])
    expect(page.name).to eq(raw_page["name"])
    expect(page.path).to eq(raw_page["path"])
    expect(page.body).to eq(raw_body)
  end
  
  it "updates pages in sub folders" do
    @updater.update("page_2/")

    page = LandingPages::Page.find_by('name', raw_page_2['name'])
    expect(page.name).to eq(raw_page_2["name"])
    expect(page.path).to eq(raw_page_2["path"])
    expect(page.body).to eq(raw_body_2)
  end
end