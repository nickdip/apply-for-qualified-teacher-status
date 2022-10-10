# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assessor reviewing further information", type: :system do
  it "reviewing further information" do
    given_the_service_is_open
    given_i_am_authorized_as_a_user(assessor)
    given_there_is_an_application_form_with_failure_reasons
    given_there_is_further_information_received

    when_i_visit_the(:assessor_application_page, application_id:)
    and_i_click_review_requested_information
    then_i_see_the(
      :review_further_information_request_page,
      application_id:,
      assessment_id:,
      further_information_request_id:,
    )
  end

  private

  def given_there_is_an_application_form_with_failure_reasons
    application_form
  end

  def given_there_is_further_information_received
    further_information_request
  end

  def and_i_click_review_requested_information
    assessor_application_page.review_requested_information_task.link.click
  end

  def application_form
    @application_form ||=
      create(
        :application_form,
        :with_personal_information,
        :submitted,
      ).tap do |application_form|
        assessment =
          create(:assessment, :request_further_information, application_form:)
        create(
          :assessment_section,
          :qualifications,
          :failed,
          assessment:,
          selected_failure_reasons: {
            qualifications_dont_support_subjects: "A note.",
          },
        )
      end
  end

  def further_information_request
    @further_information_request ||=
      create(
        :further_information_request,
        :received,
        assessment: application_form.assessment,
      )
  end

  def assessor
    @assessor ||= create(:staff, :confirmed)
  end

  def application_id
    application_form.id
  end

  def assessment_id
    application_form.assessment.id
  end

  def further_information_request_id
    further_information_request.id
  end
end
