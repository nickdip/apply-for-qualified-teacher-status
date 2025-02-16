# frozen_string_literal: true

module PageObjects
  module AssessorInterface
    class Application < SitePrism::Page
      set_url "/assessor/applications/{reference}"

      element :back_link, "a", text: "Back"

      element :add_note_button, ".app-inline-action .govuk-button"

      section :summary_list, GovukSummaryList, ".govuk-summary-list"
      section :task_list, TaskList, ".app-task-list"

      section :management_tasks, ".app-task-list + .govuk-warning-text" do
        elements :links, ".govuk-link"
      end

      def name_summary
        summary_list.find_row(key: "Name")
      end

      def assessor_summary
        summary_list.find_row(key: "Assigned to")
      end

      def reviewer_summary
        summary_list.find_row(key: "Reviewer")
      end

      def status_summary
        summary_list.find_row(key: "Status")
      end

      def preliminary_check_task
        task_list.find_item("Preliminary check (qualifications)")
      end

      def awaiting_professional_standing_task
        task_list.find_item("Awaiting third-party professional standing")
      end

      def personal_information_task
        task_list.find_item("Check personal information")
      end

      def qualifications_task
        task_list.find_item("Check qualifications")
      end

      def age_range_subjects_task
        task_list.find_item("Verify age range and subjects")
      end

      def english_language_proficiency_task
        task_list.find_item("Check English language proficiency")
      end

      def work_history_task
        task_list.find_item("Check work history")
      end

      def professional_standing_task
        task_list.find_item("Check professional standing")
      end

      def review_requested_information_task
        task_list.find_item("Review requested information from applicant")
      end

      def record_qualification_requests_task
        task_list.find_item("Record qualifications responses")
      end

      def review_qualification_requests_task
        task_list.find_item("Review qualifications responses")
      end

      def verify_references_task
        task_list.find_item("Verify references")
      end

      def verify_professional_standing_task
        task_list.find_item("Verify LoPS")
      end

      def assessment_decision_task
        task_list.find_item("Assessment decision")
      end

      def review_verifications_task
        task_list.find_item("Review verifications")
      end

      def verification_decision_task
        task_list.find_item("Verification decision")
      end
    end
  end
end
