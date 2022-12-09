# frozen_string_literal: true

class UpdateAssessmentSection
  include ServicePattern

  def initialize(assessment_section:, user:, params:)
    @assessment_section = assessment_section
    @params = params
    @user = user
    @selected_failure_reasons = params.delete(:selected_failure_reasons)
  end

  def call
    old_state = assessment_section.state

    ActiveRecord::Base.transaction do
      selected_keys = selected_failure_reasons.keys

      assessment_section
        .assessment_section_failure_reasons
        .where.not(key: selected_keys)
        .destroy_all

      selected_failure_reasons.each do |key, assessor_feedback|
        assessment_section
          .assessment_section_failure_reasons
          .find_or_initialize_by(key:)
          .update(assessor_feedback:)
      end

      next false unless assessment_section.update(params)

      update_application_form_state
      update_application_form_assessor
      create_timeline_event(old_state:)
      update_assessment_started_at

      true
    end
  end

  private

  attr_reader :assessment_section, :user, :params, :selected_failure_reasons

  delegate :assessment, to: :assessment_section
  delegate :application_form, to: :assessment

  def update_application_form_state
    if application_form.submitted?
      ChangeApplicationFormState.call(
        application_form:,
        user:,
        new_state: "initial_assessment",
      )
    end
  end

  def update_application_form_assessor
    if application_form.assessor.nil?
      AssignApplicationFormAssessor.call(
        application_form:,
        user:,
        assessor: user,
      )
    end
  end

  def create_timeline_event(old_state:)
    new_state = assessment_section.state
    return if old_state == new_state

    TimelineEvent.create!(
      creator: user,
      event_type: :assessment_section_recorded,
      assessment_section:,
      application_form:,
      old_state:,
      new_state:,
    )
  end

  def update_assessment_started_at
    return if assessment.started_at
    assessment.update!(started_at: Time.zone.now)
  end
end
