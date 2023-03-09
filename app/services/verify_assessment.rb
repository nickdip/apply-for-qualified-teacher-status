# frozen_string_literal: true

class VerifyAssessment
  include ServicePattern

  def initialize(assessment:, user:, qualifications:, work_histories:)
    @assessment = assessment
    @user = user
    @qualifications = qualifications
    @work_histories = work_histories
  end

  def call
    reference_requests =
      ActiveRecord::Base.transaction do
        assessment.verify!

        create_qualification_requests
        reference_requests = create_reference_requests

        ApplicationFormStatusUpdater.call(application_form:, user:)

        reference_requests
      end

    send_reference_request_emails(reference_requests)

    reference_requests
  end

  private

  attr_reader :assessment, :user, :qualifications, :work_histories

  delegate :application_form, to: :assessment
  delegate :teacher, to: :application_form

  def create_qualification_requests
    qualifications.map do |qualification|
      QualificationRequest
        .create!(assessment:, qualification:)
        .tap { |requestable| create_timeline_event(requestable) }
    end
  end

  def create_reference_requests
    work_histories.map do |work_history|
      ReferenceRequest
        .create!(assessment:, work_history:)
        .tap { |requestable| create_timeline_event(requestable) }
    end
  end

  def create_timeline_event(requestable)
    TimelineEvent.create!(
      application_form:,
      creator: user,
      event_type: "requestable_requested",
      requestable:,
    )
  end

  def send_reference_request_emails(reference_requests)
    reference_requests.each do |reference_request|
      RefereeMailer.with(reference_request:).reference_requested.deliver_later
    end

    TeacherMailer.with(teacher:).references_requested.deliver_later
  end
end
