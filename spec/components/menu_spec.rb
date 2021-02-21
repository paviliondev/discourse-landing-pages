require_relative '../plugin_helper'

describe LandingPages::Menu do
  fab!(:user) { Fabricate(:user) }

  let(:raw_global) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/pages.json"
    ).read)
  }
  
  it "creates a menu" do
    menu = LandingPages::Menu.create(raw_global['menus'][0])
    
    expect(menu.name).to eq(raw_global['menus'][0]['name'].parameterize.underscore)
    expect(menu.items.length).to eq(raw_global['menus'][0]['items'].length)
  end
  
  it "destroys a menu" do
    menu = LandingPages::Menu.create(raw_global['menus'][0])
    LandingPages::Menu.destroy(menu.id)
    
    expect(LandingPages::Menu.find(menu.id)).to eq(nil)
  end
end