module HostingEnvironment
  class << self
    def name
      ENV.fetch("HOSTING_ENVIRONMENT", "dev")
    end

    def phase
      return "Beta" if production?
      return "Development" if development?
      return "Pre-production" if preprod?

      name.capitalize
    end

    def phase_text
      return I18n.t("service.phase_banner_text") if production?

      "This is a '#{phase}' version of the service."
    end

    def host
      return "apply-for-qts-in-england.education.gov.uk" if production?
      return "#{application_name}.london.cloudapps.digital" if review?

      "#{name}.apply-for-qts-in-england.education.gov.uk"
    end

    def production?
      name == "production"
    end

    def preprod?
      name == "preprod"
    end

    def development?
      name == "dev"
    end

    def review?
      name == "review"
    end

    def application_name
      vcap_json = ENV.fetch("VCAP_APPLICATION", "{}")
      vcap_config = JSON.parse(vcap_json)

      (vcap_config["application_name"] || name).gsub(/-worker$/, "")
    end
  end
end
