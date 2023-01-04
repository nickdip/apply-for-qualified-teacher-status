# frozen_string_literal: true

class FailureReasons
  DECLINABLE = [
    AGE_RANGE = "age_range",
    APPLICANT_ALREADY_QTS = "applicant_already_qts",
    AUTHORISATION_TO_TEACH = "authorisation_to_teach",
    CONFIRM_AGE_RANGE_SUBJECTS = "confirm_age_range_subjects",
    DUPLICATE_APPLICATION = "duplicate_application",
    FULL_PROFESSIONAL_STATUS = "full_professional_status",
    NOT_QUALIFIED_TO_TEACH_MAINSTREAM = "not_qualified_to_teach_mainstream",
    TEACHING_HOURS_NOT_FULFILLED = "teaching_hours_not_fulfilled",
    TEACHING_QUALIFICATION = "teaching_qualification",
    TEACHING_QUALIFICATION_1_YEAR = "teaching_qualification_1_year",
    TEACHING_QUALIFICATION_PEDAGOGY = "teaching_qualification_pedagogy",
    TEACHING_QUALIFICATIONS_FROM_INELIGIBLE_COUNTRY =
      "teaching_qualifications_from_ineligible_country",
    TEACHING_QUALIFICATIONS_NOT_AT_REQUIRED_LEVEL =
      "teaching_qualifications_not_at_required_level",
  ].freeze

  FURTHER_INFORMATIONABLE = [
    ADDITIONAL_DEGREE_CERTIFICATE_ILLEGIBLE =
      "additional_degree_certificate_illegible",
    ADDITIONAL_DEGREE_TRANSCRIPT_ILLEGIBLE =
      "additional_degree_transcript_illegible",
    APPLICANT_ALREADY_DQT = "applicant_already_dqt",
    APPLICATION_AND_QUALIFICATION_NAMES_DO_NOT_MATCH =
      "application_and_qualification_names_do_not_match",
    DEGREE_CERTIFICATE_ILLEGIBLE = "degree_certificate_illegible",
    DEGREE_TRANSCRIPT_ILLEGIBLE = "degree_transcript_illegible",
    IDENTIFICATION_DOCUMENT_EXPIRED = "identification_document_expired",
    IDENTIFICATION_DOCUMENT_ILLEGIBLE = "identification_document_illegible",
    IDENTIFICATION_DOCUMENT_MISMATCH = "identification_document_mismatch",
    NAME_CHANGE_DOCUMENT_ILLEGIBLE = "name_change_document_illegible",
    QUALIFICATIONS_DONT_MATCH_OTHER_DETAILS =
      "qualifications_dont_match_other_details",
    QUALIFICATIONS_DONT_MATCH_SUBJECTS = "qualifications_dont_match_subjects",
    QUALIFIED_TO_TEACH = "qualified_to_teach",
    REGISTRATION_NUMBER = "registration_number",
    SATISFACTORY_EVIDENCE_WORK_HISTORY = "satisfactory_evidence_work_history",
    TEACHING_CERTIFICATE_ILLEGIBLE = "teaching_certificate_illegible",
    TEACHING_TRANSCRIPT_ILLEGIBLE = "teaching_transcript_illegible",
    WRITTEN_STATEMENT_ILLEGIBLE = "written_statement_illegible",
    WRITTEN_STATEMENT_RECENT = "written_statement_recent",
  ].freeze

  ALL = (DECLINABLE + FURTHER_INFORMATIONABLE).freeze

  DOCUMENT_FAILURE_REASONS = {
    ADDITIONAL_DEGREE_CERTIFICATE_ILLEGIBLE => :qualification_certificate,
    ADDITIONAL_DEGREE_TRANSCRIPT_ILLEGIBLE => :qualification_transcript,
    APPLICATION_AND_QUALIFICATION_NAMES_DO_NOT_MATCH => :name_change,
    DEGREE_CERTIFICATE_ILLEGIBLE => :qualification_certificate,
    DEGREE_TRANSCRIPT_ILLEGIBLE => :qualification_transcript,
    IDENTIFICATION_DOCUMENT_EXPIRED => :identification,
    IDENTIFICATION_DOCUMENT_ILLEGIBLE => :identification,
    IDENTIFICATION_DOCUMENT_MISMATCH => :name_change,
    NAME_CHANGE_DOCUMENT_ILLEGIBLE => :name_change,
    QUALIFICATIONS_DONT_MATCH_SUBJECTS => :qualification_document,
    QUALIFIED_TO_TEACH => :written_statement,
    REGISTRATION_NUMBER => :written_statement,
    TEACHING_CERTIFICATE_ILLEGIBLE => :qualification_certificate,
    TEACHING_TRANSCRIPT_ILLEGIBLE => :qualification_transcript,
    WRITTEN_STATEMENT_ILLEGIBLE => :written_statement,
    WRITTEN_STATEMENT_RECENT => :written_statement,
  }.freeze

  def self.decline?(failure_reason:)
    DECLINABLE.include?(failure_reason.to_s)
  end

  def self.further_information_request_document_type(failure_reason:)
    DOCUMENT_FAILURE_REASONS[failure_reason.to_s]
  end
end
