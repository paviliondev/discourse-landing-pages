require_relative '../plugin_helper'

describe LandingPages::Remote do
  fab!(:user) { Fabricate(:user) }

  let(:raw_remote) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/remote.json"
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
  
  it "updates the remote" do
    LandingPages::Remote.update(raw_remote)
    remote = LandingPages::Remote.get
    
    expect(remote.url).to eq(raw_remote['url'])
  end
  
  it "destroys the remote" do
    remote = LandingPages::Remote.update(raw_remote)
    LandingPages::Remote.destroy
    
    expect(LandingPages::Remote.get).to eq(nil)
  end
  
  it "removes remote from pages imported from a destroyed remote" do
    remote = LandingPages::Remote.update(raw_remote)
    raw_page[:remote] = 'https://github.com/paviliondev/pages-repo.git'
    raw_page[:body] = raw_body
    page = LandingPages::Page.create(raw_page)

    expect(page.remote).to eq('https://github.com/paviliondev/pages-repo.git')
    
    LandingPages::Remote.destroy
    
    page = LandingPages::Page.find_by('name', raw_page['name'])
    
    expect(page).to eq(nil)
  end
end