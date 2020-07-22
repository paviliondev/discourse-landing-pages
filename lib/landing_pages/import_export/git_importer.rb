# frozen_string_literal: true

class LandingPages::GitImporter < ThemeStore::GitImporter
  attr_reader :temp_folder
  
  def initialize(url, private_key: nil, branch: nil)
    @url = url
    if @url.present? && @url.start_with?("https://github.com") && !@url.end_with?(".git")
      @url = @url.gsub(/\/$/, '')
      @url += ".git"
    end
    @temp_folder = "#{Pathname.new(Dir.tmpdir).realpath}/landing_page_#{SecureRandom.hex}"
    @private_key = private_key
    @branch = branch
  end
end