# frozen_string_literal: true
require_relative '../plugin_helper'

describe LandingPages::Menu do
  let(:raw_global) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/pages.json"
    ).read)
  }

  it "creates a menu" do
    raw_menu = raw_global["menus"].first
    menu = LandingPages::Menu.create(raw_menu)

    expect(menu.name).to eq(raw_menu["name"].underscore)
    expect(menu.items).to eq(raw_menu["items"])
  end

  it "does not create a menu if required attributes are missing" do
    raw_menu = raw_global["menus"].first
    raw_menu['name'] = nil
    menu = LandingPages::Menu.create(raw_menu)

    expect(menu.errors.full_messages.first).to eq(
      I18n.t("landing_pages.error.attr_required", attr: 'name')
    )
  end

  it "destroys a menu" do
    raw_menu = raw_global["menus"].first
    menu = LandingPages::Menu.create(raw_menu)

    expect(LandingPages::Menu.exists?(menu.id)).to eq(false)
  end

  it "lists menus" do
    raw_menu = raw_global["menus"].first
    LandingPages::Menu.create(raw_menu)

    expect(LandingPages::Menu.all.length).to eq(1)
  end
end
