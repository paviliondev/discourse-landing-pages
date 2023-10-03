# frozen_string_literal: true

describe LandingPages::LandingController do
  fab!(:admin_user) { Fabricate(:admin) }

  before do
    LandingPages::Page.create({ name: "Public", path: "public", body: "body" })
    LandingPages::Page.create({ name: "Private", path: "private", group_ids: [1], body: "body" })
  end

  after do
    LandingPages::Page.find_by(:path, "public").destroy
    LandingPages::Page.find_by(:path, "private").destroy
  end

  it "shows a public page" do
    get "/public"
    expect(response.status).to eq(200)
  end

  it "shows a private page if its group restrictions are met" do
    sign_in(admin_user)
    get "/private"
    expect(response.status).to eq(200)
  end

  it "forbids access to a private page if its group restrictions are not met" do
    get "/private"
    expect(response.status).to eq(403)
  end
end
