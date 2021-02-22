# frozen_string_literal: true

class LandingPages::Importer  
  attr_reader :type,
              :bundle
  
  attr_accessor :handler,
                :remote,
                :report
  
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
      @handler = LandingPages::ZipImporter.new(
        bundle.tempfile.path,
        bundle.original_filename,
        temp_folder: temp_folder
      )
    elsif type == :git
      @remote = LandingPages::Remote.get
      @handler = LandingPages::GitImporter.new(@remote.url,
        private_key: @remote.private_key,
        branch: @remote.branch,
        temp_folder: temp_folder
      )
    end
    
    if @handler.blank? || !@handler.connected
      add_error(I18n.t("landing_pages.error.import_handler"))
    else
      begin
        @handler.import!
      rescue RemoteTheme::ImportError => e
        add_error(e.message || I18n.t("landing_pages.error.import_failed"))    
      end
    end
  end
  
  def files
    @handler.all_files.reduce([]) do |result, path|
      if path.match? /page.json|menu.json|assets.json|pages.json/
        folder = path.rpartition("/").first
        folder = "#{folder}/" if folder.length > 0
        result.push(folder) if result.exclude?(folder)
      end
      result
    end
  end
  
  def temp_folder
    "#{Pathname.new(Dir.tmpdir).realpath}/landing_page_#{SecureRandom.hex}"
  end
  
  def update!
    updater = LandingPages::Updater.new(type, handler)

    files.each do |path|
      updater.update(path)

      if updater.errors.any?
        add_error(updater.errors.full_messages.join(", "))
      else
        import_complete(updater.updated)
      end
    end
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
end