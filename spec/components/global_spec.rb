require_relative '../plugin_helper'

describe LandingPages::Global do
  fab!(:user) { Fabricate(:user) }

  let(:raw_global) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/pages.json"
    ).read)
  }
  
  it "saves a global record" do
    global = LandingPages::Global.new(raw_global)
    global.save
    
    expect(global.scripts).to eq(raw_global['scripts'])
    expect(global.footer).to eq(raw_global['footer'])
    expect(global.header).to eq(raw_global['header']) 
  end
  
  it "destroys a global record" do
    global = LandingPages::Global.new(raw_global)
    global.save
    
    LandingPages::Global.destroy
    expect(LandingPages::Global.find).to eq(nil)
  end
end