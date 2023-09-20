# frozen_string_literal: true
module UploadValidatorLandingPagesExtension
  private def authorized_extensions(upload)
    return extensions_to_set(SiteSetting.landing_authorized_extensions) if upload.for_landing_page
    super
  end

  private def authorizes_all_extensions?(upload)
    if upload.for_landing_page && SiteSetting.landing_authorized_extensions.include?("*")
      return true
    end
    super
  end
end
