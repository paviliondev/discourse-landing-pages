# frozen_string_literal: true

describe DiscourseHomePages::SimplePageController do
  it "a simple page is legal" do
    get "/home-pages/sp/test"
    expect(response.status).to eq(200)
  end
end
