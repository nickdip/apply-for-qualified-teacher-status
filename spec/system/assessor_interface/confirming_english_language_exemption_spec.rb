require "rails_helper"

RSpec.describe "Assessor confirms English language exemption", type: :system do
  it "via the Personal Information section" do
    given_the_service_is_open
    given_there_is_an_application_form
    and_the_application_states_english_language_exemption_by_citizenship
    given_i_am_authorized_as_an_assessor_user

    when_i_visit_the(:assessor_application_page, application_id:)
    then_i_see_the_application

    when_i_visit_the(
      :check_english_language_proficiency_page,
      application_id:,
      assessment_id:,
    )
    then_i_am_asked_to_confirm_english_language_proficiency_in_the_personal_information_section

    when_i_visit_the(
      :check_personal_information_page,
      application_id:,
      assessment_id:,
    )
    and_i_confirm_english_language_exemption(check_personal_information_page)
    and_i_confirm_the_section_as_complete(check_personal_information_page)
    then_i_see_the_personal_information_section_is_complete
    and_the_english_language_section_is_complete
  end

  it "via the Qualifications section" do
    given_the_service_is_open
    given_there_is_an_application_form
    and_the_application_states_english_language_exemption_by_qualification
    given_i_am_authorized_as_an_assessor_user

    when_i_visit_the(:assessor_application_page, application_id:)
    then_i_see_the_application

    when_i_visit_the(
      :check_english_language_proficiency_page,
      application_id:,
      assessment_id:,
    )
    then_i_am_asked_to_confirm_english_language_proficiency_in_the_qualifications_section

    when_i_visit_the(
      :check_qualifications_page,
      application_id:,
      assessment_id:,
    )
    and_i_confirm_english_language_exemption(check_qualifications_page)
    and_i_confirm_the_section_as_complete(check_qualifications_page)
    then_i_see_the_qualifications_section_is_complete
    and_the_english_language_section_is_complete
  end

  private

  def given_there_is_an_application_form
    application_form
  end

  def and_the_application_states_english_language_exemption_by_citizenship
    application_form.update!(english_language_citizenship_exempt: true)
  end

  def and_the_application_states_english_language_exemption_by_qualification
    application_form.update!(english_language_qualification_exempt: true)
  end

  def then_i_see_the_application
    expect(assessor_application_page.overview.name.text).to eq(
      "#{application_form.given_names} #{application_form.family_name}",
    )
  end

  def then_i_am_asked_to_confirm_english_language_proficiency_in_the_personal_information_section
    expect(check_english_language_proficiency_page.heading.text).to eq(
      "Check English language proficiency",
    )
    expect(
      check_english_language_proficiency_page.exemption_heading.text,
    ).to eq("English language exemption by birth/citizenship")
    check_english_language_proficiency_page.return_button.click
  end

  def then_i_am_asked_to_confirm_english_language_proficiency_in_the_qualifications_section
    expect(check_english_language_proficiency_page.heading.text).to eq(
      "Check English language proficiency",
    )
    expect(
      check_english_language_proficiency_page.exemption_heading.text,
    ).to eq("English language exemption by qualification")
    check_english_language_proficiency_page.return_button.click
  end

  def and_i_confirm_english_language_exemption(page)
    page.exemption_form.english_language_exempt.check
  end

  def and_i_confirm_the_section_as_complete(page)
    page.form.yes_radio_item.choose
    page.form.continue_button.click
  end

  def then_i_see_the_personal_information_section_is_complete
    assert_section_is_complete(:personal_information)
  end

  def then_i_see_the_qualifications_section_is_complete
    assert_section_is_complete(:qualifications)
  end

  def and_the_english_language_section_is_complete
    assert_section_is_complete(:english_language_proficiency)
  end

  def assert_section_is_complete(section)
    expect(
      assessor_application_page.send("#{section}_task").status_tag.text,
    ).to eq("COMPLETED")
  end

  def application_form
    @application_form ||=
      begin
        application_form =
          create(
            :application_form,
            :with_work_history,
            :with_personal_information,
            :submitted,
            :with_assessment,
          )

        create(
          :assessment_section,
          :personal_information,
          assessment: application_form.assessment,
        )
        create(
          :assessment_section,
          :qualifications,
          assessment: application_form.assessment,
        )
        create(
          :assessment_section,
          :english_language_proficiency,
          assessment: application_form.assessment,
        )

        application_form
      end
  end

  def application_id
    application_form.id
  end

  def assessment_id
    application_form.assessment.id
  end
end
