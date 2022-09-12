module PageObjects
  module AssessorInterface
    class PersonalInformationCard < SitePrism::Section
      element :heading, "h2"
      element :given_names,
              "dl.govuk-summary-list > div:nth-of-type(1) > dd:nth-of-type(1)"
      element :family_name,
              "dl.govuk-summary-list > div:nth-of-type(2) > dd:nth-of-type(1)"
    end

    class CheckPersonalInformation < AssessmentSection
      set_url "/assessor/applications/{application_id}/assessments/{assessment_id}/sections/personal_information"

      sections :cards, PersonalInformationCard, ".govuk-summary-list__card"

      def personal_information
        cards&.first
      end
    end
  end
end
