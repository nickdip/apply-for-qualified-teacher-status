# frozen_string_literal: true

class AssessmentFactory
  include ServicePattern

  def initialize(application_form:)
    @application_form = application_form
  end

  def call
    sections = [
      personal_information_section,
      qualifications_section,
      age_range_subjects_section,
      english_language_proficiency_section,
      work_history_section,
      professional_standing_section,
    ].compact

    Assessment.create!(
      application_form:,
      sections:,
      age_range_min: application_form.age_range_min,
      age_range_max: application_form.age_range_max,
    )
  end

  private

  attr_reader :application_form

  def personal_information_section
    checks = [
      :identification_document_present,
      (:name_change_document_present if application_form.has_alternative_name),
      :duplicate_application,
      :applicant_already_qts,
      :applicant_already_dqt,
    ].compact

    failure_reasons = [
      FailureReasons::IDENTIFICATION_DOCUMENT_EXPIRED,
      FailureReasons::IDENTIFICATION_DOCUMENT_ILLEGIBLE,
      FailureReasons::IDENTIFICATION_DOCUMENT_MISMATCH,
      (
        if application_form.has_alternative_name
          FailureReasons::NAME_CHANGE_DOCUMENT_ILLEGIBLE
        end
      ),
      FailureReasons::DUPLICATE_APPLICATION,
      FailureReasons::APPLICANT_ALREADY_QTS,
      FailureReasons::APPLICANT_ALREADY_DQT,
    ].compact

    AssessmentSection.new(
      key: "personal_information",
      checks:,
      failure_reasons:,
    )
  end

  def qualifications_section
    checks = [
      "qualifications_meet_level_6_or_equivalent",
      "teaching_qualifications_completed_in_eligible_country",
      "qualified_in_mainstream_education",
      (
        if application_form.secondary_education_teaching_qualification_required?
          "qualified_to_teach_children_11_to_16"
        end
      ),
      (
        if application_form.secondary_education_teaching_qualification_required?
          "teaching_qualification_subjects_criteria"
        end
      ),
      "has_teacher_qualification_certificate",
      "has_teacher_qualification_transcript",
      "has_university_degree_certificate",
      "has_university_degree_transcript",
      "has_additional_qualification_certificate",
      "has_additional_degree_transcript",
      (
        if application_form.created_under_new_regulations?
          "teaching_qualification_pedagogy"
        end
      ),
      (
        if application_form.created_under_new_regulations?
          "teaching_qualification_1_year"
        end
      ),
    ].compact

    failure_reasons = [
      FailureReasons::APPLICATION_AND_QUALIFICATION_NAMES_DO_NOT_MATCH,
      FailureReasons::TEACHING_QUALIFICATIONS_FROM_INELIGIBLE_COUNTRY,
      FailureReasons::TEACHING_QUALIFICATIONS_NOT_AT_REQUIRED_LEVEL,
      FailureReasons::TEACHING_HOURS_NOT_FULFILLED,
      (
        if application_form.created_under_new_regulations?
          FailureReasons::TEACHING_QUALIFICATION_PEDAGOGY
        end
      ),
      (
        if application_form.created_under_new_regulations?
          FailureReasons::TEACHING_QUALIFICATION_1_YEAR
        end
      ),
      FailureReasons::NOT_QUALIFIED_TO_TEACH_MAINSTREAM,
      FailureReasons::QUALIFICATIONS_DONT_MATCH_SUBJECTS,
      FailureReasons::QUALIFICATIONS_DONT_MATCH_OTHER_DETAILS,
      (
        if application_form.secondary_education_teaching_qualification_required?
          FailureReasons::QUALIFIED_TO_TEACH_CHILDREN_11_TO_16
        end
      ),
      (
        if application_form.secondary_education_teaching_qualification_required?
          FailureReasons::TEACHING_QUALIFICATION_SUBJECTS_CRITERIA
        end
      ),
      FailureReasons::TEACHING_CERTIFICATE_ILLEGIBLE,
      FailureReasons::TEACHING_TRANSCRIPT_ILLEGIBLE,
      FailureReasons::DEGREE_CERTIFICATE_ILLEGIBLE,
      FailureReasons::DEGREE_TRANSCRIPT_ILLEGIBLE,
      FailureReasons::ADDITIONAL_DEGREE_CERTIFICATE_ILLEGIBLE,
      FailureReasons::ADDITIONAL_DEGREE_TRANSCRIPT_ILLEGIBLE,
    ].compact

    AssessmentSection.new(key: "qualifications", checks:, failure_reasons:)
  end

  def age_range_subjects_section
    checks = [
      "qualified_in_mainstream_education",
      (
        if application_form.secondary_education_teaching_qualification_required?
          "qualified_to_teach_children_11_to_16"
        end
      ),
      (
        if application_form.secondary_education_teaching_qualification_required?
          "teaching_qualification_subjects_criteria"
        end
      ),
      "age_range_subjects_matches",
    ].compact

    failure_reasons = [
      FailureReasons::NOT_QUALIFIED_TO_TEACH_MAINSTREAM,
      FailureReasons::AGE_RANGE,
    ]

    AssessmentSection.new(key: "age_range_subjects", checks:, failure_reasons:)
  end

  def english_language_proficiency_section
    checks =
      if application_form.english_language_exempt?
        []
      elsif application_form.english_language_proof_method_medium_of_instruction?
        %i[english_language_valid_moi]
      else
        %i[english_language_valid_provider]
      end

    failure_reasons =
      if application_form.english_language_exempt?
        []
      elsif application_form.english_language_proof_method_medium_of_instruction?
        [
          FailureReasons::EL_MOI_NOT_TAUGHT_IN_ENGLISH,
          FailureReasons::EL_MOI_INVALID_FORMAT,
        ]
      else
        [
          FailureReasons::EL_QUALIFICATION_INVALID,
          FailureReasons::EL_UNVERIFIABLE_REFERENCE_NUMBER,
          FailureReasons::EL_GRADE_BELOW_B2,
          FailureReasons::EL_SELT_EXPIRED,
        ]
      end

    AssessmentSection.new(
      key: "english_language_proficiency",
      checks:,
      failure_reasons:,
    )
  end

  def work_history_section
    return nil unless application_form.needs_work_history

    under_new_regs =
      application_form.created_under_new_regulations? &&
        FeatureFlags::FeatureFlag.active?(:application_work_history)

    checks =
      if under_new_regs
        %i[verify_school_details work_history_references]
      else
        %i[email_contact_current_employer satisfactory_evidence_work_history]
      end

    failure_reasons =
      if under_new_regs
        [
          FailureReasons::WORK_HISTORY_BREAK,
          FailureReasons::SCHOOL_DETAILS_CANNOT_BE_VERIFIED,
        ]
      else
        [FailureReasons::SATISFACTORY_EVIDENCE_WORK_HISTORY]
      end

    AssessmentSection.new(key: "work_history", checks:, failure_reasons:)
  end

  def professional_standing_section
    unless application_form.needs_written_statement ||
             application_form.needs_registration_number
      return nil
    end

    checks = [
      application_form.needs_registration_number ? :registration_number : nil,
      (:written_statement_present if application_form.needs_written_statement),
      (:written_statement_recent if application_form.needs_written_statement),
      :authorisation_to_teach,
      :teaching_qualification,
      :confirm_age_range_subjects,
      :qualified_to_teach,
      :full_professional_status,
    ].compact

    failure_reasons = [
      (
        if application_form.needs_registration_number
          FailureReasons::REGISTRATION_NUMBER
        end
      ),
      (
        if application_form.needs_written_statement
          FailureReasons::WRITTEN_STATEMENT_ILLEGIBLE
        end
      ),
      (
        if application_form.needs_written_statement
          FailureReasons::WRITTEN_STATEMENT_RECENT
        end
      ),
      FailureReasons::AUTHORISATION_TO_TEACH,
      FailureReasons::TEACHING_QUALIFICATION,
      FailureReasons::CONFIRM_AGE_RANGE_SUBJECTS,
      FailureReasons::QUALIFIED_TO_TEACH,
      FailureReasons::FULL_PROFESSIONAL_STATUS,
    ].compact

    AssessmentSection.new(
      key: "professional_standing",
      checks:,
      failure_reasons:,
    )
  end
end
