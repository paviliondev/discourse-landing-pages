module ContentSecurityPolicyLandingPagesExtension
  def path_specific_extension(path_info)
    super.tap do |obj|
      obj[:script_src] ||= []
      obj[:script_src] = [*obj[:script_src]].concat(
        LandingPages::Global.scripts
      ) if LandingPages::Global.scripts.present?
    end
  end
end