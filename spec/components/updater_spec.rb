# frozen_string_literal: true
require_relative '../plugin_helper'

describe LandingPages::Updater do
  let(:raw_remote) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/remote.json"
      ).read
    ).with_indifferent_access
  }
  let(:raw_global) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/pages.json"
      ).read
    ).with_indifferent_access
  }
  let(:raw_assets) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/assets.json"
      ).read
    ).with_indifferent_access
  }
  let(:raw_page) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/page.json"
      ).read
    ).with_indifferent_access
  }
  let(:raw_body) {
    File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/body.html.erb"
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
    @updater.update_global(raw_global)

    global = LandingPages::Global.find
    expect(global.scripts).to eq(raw_global['scripts'])
    expect(global.footer).to eq(raw_global['footer'])
    expect(global.header).to eq(raw_global['header'])
  end

  it "updates assets" do
    @updater.update_assets(raw_assets)

    assets = LandingPages::Asset.all
    expect(raw_assets['register'].keys).to contain_exactly(assets.first.name, assets.second.name)
  end

  it "updates pages" do
    raw_page['body'] = raw_body
    @updater.update_page(raw_page)

    page = LandingPages::Page.find_by('name', raw_page['name'])
    expect(page.name).to eq(raw_page["name"])
    expect(page.path).to eq(raw_page["path"])
    expect(page.body).to eq(raw_body)
  end
end
