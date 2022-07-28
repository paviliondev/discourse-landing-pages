# frozen_string_literal: true
module UploadCreatorLandingPagesExtension
  def add_metadata!
    @upload.for_landing_page = true if @opts[:for_landing_page]
    super
  end
end
