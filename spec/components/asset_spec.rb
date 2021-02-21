require_relative '../plugin_helper'

describe LandingPages::Asset do
  fab!(:user) { Fabricate(:user) }

  let(:asset_1_path) {
    "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/asset_1.json"
  }
  
  let(:asset_2_path) {
    "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/asset_2.json"
  }
  
  it "creates an asset" do
    asset_file = File.new(asset_1_path)
    asset = LandingPages::Asset.create(name: 'animation', file: asset_file)
    expect(asset.name).to eq("animation")
  end
  
  it "does not create an asset if required attributes are missing" do
    asset = LandingPages::Asset.create(name: 'animation', file: nil)
    expect(asset.errors.full_messages.first).to eq(
      I18n.t("landing_pages.error.attr_required", attr: 'file')
    )
  end
  
  it "creates an upload for an asset" do
    asset_file = File.new(asset_1_path)
    asset = LandingPages::Asset.create(name: 'animation', file: asset_file)
    
    expect(asset.upload_id.present?).to eq(true)
    
    upload = Upload.find(asset.upload_id)

    expect(upload.present?).to eq(true)
    expect(upload.filesize).to eq(File.size(asset_1_path))
  end
  
  it "destroys an asset" do
    asset_file = File.new(asset_1_path)
    asset = LandingPages::Asset.create(name: 'animation', file: asset_file)
    LandingPages::Asset.destroy(asset.id)
    
    expect(LandingPages::Asset.find(asset.id)).to eq(nil)
  end
  
  it "lists assets" do
    asset_file = File.new(asset_1_path)
    asset = LandingPages::Asset.create(name: 'animation', file: asset_file)
    second_asset_file = File.new(asset_2_path)
    seond_asset = LandingPages::Asset.create(name: 'second_animation', file: second_asset_file)
    
    expect(LandingPages::Asset.all.length).to eq(2)
  end
  
  it "updates the asset upload if the asset file changes" do
    asset_file = File.new(asset_1_path)
    asset = LandingPages::Asset.create(name: 'animation', file: asset_file)
    
    upload = Upload.find(asset.upload_id)
    expect(upload.filesize).to eq(File.size(asset_1_path))
    
    asset.file = File.new(asset_2_path)
    asset.save
    
    expect(upload.reload.filesize).to eq(File.size(asset_2_path))
  end
end