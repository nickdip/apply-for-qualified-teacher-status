module PageObjects
  module TeacherInterface
    class PartOfUniversityDegree < SitePrism::Page
      set_url "/teacher/application/qualifications/{qualification_id}/part_of_university_degree"

      element :heading, "h1"

      section :form, "form" do
        section :yes_radio_item,
                PageObjects::GovukRadioItem,
                ".govuk-radios__item:nth-of-type(1)"
        section :no_radio_item,
                PageObjects::GovukRadioItem,
                ".govuk-radios__item:nth-of-type(2)"

        element :continue_button, ".govuk-button:not(.govuk-button--secondary)"
        element :save_and_come_back_later_button,
                ".govuk-button.govuk-button--secondary"
      end
    end
  end
end
