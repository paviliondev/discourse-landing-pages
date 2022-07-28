# frozen_string_literal: true

class LandingPages::GitImporter < ThemeStore::GitImporter
  attr_reader :temp_folder

  def initialize(url, private_key: nil, branch: nil, temp_folder: '/')
    @url = url
    if @url.present? && @url.start_with?("https://github.com") && !@url.end_with?(".git")
      @url = @url.gsub(/\/$/, '')
      @url += ".git"
    end
    @temp_folder = temp_folder
    @private_key = private_key
    @branch = branch
  end

  def connected
    return false unless @url

    begin
      response = Discourse::Utils.execute_command(
        { "GIT_SSH_COMMAND" => "ssh -i #{ssh_folder}/id_rsa -o StrictHostKeyChecking=no" },
        "git", "ls-remote", url, "--exit-code"
      )
    rescue RuntimeError => err
      response = 2
    end

    response != 2
  end

  private

  def ssh_folder
    path = "#{Pathname.new(Dir.tmpdir).realpath}/landing_page_ssh_#{SecureRandom.hex}"
    FileUtils.mkdir_p path
    File.write("#{path}/id_rsa", @private_key || '')
    FileUtils.chmod(0600, "#{path}/id_rsa")
    path
  end
end
