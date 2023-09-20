# frozen_string_literal: true

class LandingPages::Importer
  attr_reader :type, :bundle

  attr_accessor :handler, :remote, :report

  def initialize(type, bundle: nil)
    @type = type
    @bundle = bundle if bundle
  end

  def perform!
    import!
    update! if report[:errors].blank?
    cleanup!
  end

  def import!
    if type == :zip && bundle.present?
      @handler =
        LandingPages::ZipImporter.new(
          bundle.tempfile.path,
          bundle.original_filename,
          temp_folder: temp_folder,
        )
    elsif type == :git
      @remote = LandingPages::Remote.get
      @handler =
        LandingPages::GitImporter.new(
          @remote.url,
          private_key: @remote.private_key,
          branch: @remote.branch,
          temp_folder: temp_folder,
        )
    end

    if @handler.blank? || type == :git && !@handler.connected
      add_error(I18n.t("landing_pages.error.import_handler"))
    else
      begin
        @handler.import!
      rescue RemoteTheme::ImportError => e
        add_error(e.message || I18n.t("landing_pages.error.import_failed"))
      end
    end
  end

  def pages_data
    @handler
      .all_files
      .reduce([]) do |result, path|
        if path.include?("page.json")
          data = read_json(path)
          data[:body] = @handler[path.rpartition("/").first + "/body.html.erb"]

          result.push(data) if result.select { |d| d[:name] === data[:name] }.first.blank?
        end

        result
      end
      .partition { |page| !page.key?("parent") }
      .flatten
  end

  def get_data_from_file(file)
    file = @handler.all_files.select { |path| path.include?("#{file}.json") }.first

    file.present? ? read_json(file) : nil
  end

  def temp_folder
    "#{Pathname.new(Dir.tmpdir).realpath}/landing_page_#{SecureRandom.hex}"
  end

  def update!
    updater = LandingPages::Updater.new(type, handler)

    global_data = get_data_from_file("pages")
    asset_data = get_data_from_file("assets")

    return if report[:errors].any?

    updater.update_global(global_data) if global_data.present?
    updater.update_assets(asset_data) if asset_data.present?
    add_error(updater.errors.full_messages.join(", ")) if updater.errors.any?

    return if report[:errors].any?

    if pages_data.present?
      pages_data.each do |page_data|
        updater.update_page(page_data)

        if updater.errors.any?
          add_error(updater.errors.full_messages.join(", "))
          break
        end
      end
    end

    return if report[:errors].any?

    import_complete(updater.updated)
  end

  def cleanup!
    @handler.cleanup!
  end

  def report
    @report ||= { imported: nil, errors: [] }
  end

  def add_error(message, page: nil)
    error = ""
    error += "#{page}: " if page.present?
    error += message
    report[:errors].push(error)
  end

  def import_complete(updated)
    report[:imported] = updated

    if type == :git
      @remote.commit = @handler.version
      @remote.save
    end
  end

  def read_json(path)
    file = @handler[path]
    return unless file.present?

    begin
      json = JSON.parse(file)
      json.with_indifferent_access
    rescue TypeError, JSON::ParserError => error
      add_error(I18n.t("landing_pages.error.import_json", path: path, error: error))
    end
  end
end
