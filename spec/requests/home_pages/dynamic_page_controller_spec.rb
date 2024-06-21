# frozen_string_literal: true

describe DiscourseHomePages::DynamicPageController do
  it "a dynamic page is legal" do
    get "/home-pages/dp/test"
    expect(response.status).to eq(200)
  end
end
