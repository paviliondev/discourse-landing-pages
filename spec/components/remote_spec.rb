# frozen_string_literal: true
require_relative "../plugin_helper"

describe LandingPages::Remote do
  let(:raw_remote) do
    JSON.parse(
      File.open("#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/remote.json").read,
    )
  end

  let(:raw_page) do
    JSON.parse(
      File.open("#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/page.json").read,
    )
  end

  let(:raw_body) do
    File.open("#{Rails.root}/plugins/discourse-landing-pages/spec/fixtures/body.html.erb").read
  end

  before do
    commit_hash = "69acc9abf1026c038ae99a0c91f4e15afa454333"
    commits_behind = 3

    LandingPages::GitImporter.any_instance.stubs(:import!).returns(true)
    LandingPages::GitImporter.any_instance.stubs(:connected).returns(true)
    LandingPages::GitImporter
      .any_instance
      .stubs(:commits_since)
      .returns([commit_hash, commits_behind])

    @remote = LandingPages::Remote.update(raw_remote)
  end

  it "updates the remote" do
    expect(LandingPages::Remote.get.url).to eq(raw_remote["url"])
  end

  it "destroys the remote" do
    LandingPages::Remote.destroy
    expect(LandingPages::Remote.exists?).to eq(false)
  end

  it "removes remote from pages imported from a destroyed remote" do
    raw_page["remote"] = "https://github.com/paviliondev/pages-repo.git"
    raw_page["body"] = raw_body

    page = LandingPages::Page.create(raw_page)
    expect(page.remote).to eq("https://github.com/paviliondev/pages-repo.git")

    LandingPages::Remote.destroy
    expect(LandingPages::Remote.exists?).to eq(false)

    page = LandingPages::Page.find_by("name", raw_page["name"])
    expect(page.remote).to eq(nil)
  end

  it "returns commits behind latest commit" do
    expect(@remote.commits_behind).to eq(3)
  end

  it "returns connected state of git handler" do
    expect(@remote.connected).to eq(true)
  end
end
