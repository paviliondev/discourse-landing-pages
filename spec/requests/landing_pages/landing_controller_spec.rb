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

  it "sends back a json representation of the page" do
    get "/public.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body["page"]["body"]).to eq("body")
  end

  it "shows the normal page if the user agent is a bot" do
    SiteSetting.landing_redirect_to_homepages = false
    get "/public", headers: { "HTTP_USER_AGENT" => "Googlebot" }
    expect(response.status).to eq(200)
    expect(response.parsed_body["body"]).to eq("body")
  end

  it "shows the normal page if the user agent is a bot even if redirect to Home Page TC is set" do
    SiteSetting.landing_redirect_to_homepages = true
    get "/public", headers: { "HTTP_USER_AGENT" => "Googlebot" }
    expect(response.status).to eq(200)
    expect(response.parsed_body["body"]).to eq("body")
  end

  it "shows the normal page if redirect to Home Page TC is set to false" do
    SiteSetting.landing_redirect_to_homepages = false
    get "/public"
    expect(response.status).to eq(200)
    expect(response.parsed_body["body"]).to eq("body")
  end
end
