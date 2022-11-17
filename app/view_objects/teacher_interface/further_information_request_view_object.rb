# frozen_string_literal: true

module TeacherInterface
  class FurtherInformationRequestViewObject
    def initialize(current_teacher:, params:)
      @current_teacher = current_teacher
      @params = params
    end

    def further_information_request
      @further_information_request ||=
        FurtherInformationRequest
          .joins(:assessment)
          .requested
          .where(assessments: { application_form: })
          .find(params[:id])
    end

    def task_items
      further_information_request
        .items
        .order(:created_at)
        .map do |item|
          {
            key: item.id,
            text: item_text(item),
            href: [
              :edit,
              :teacher_interface,
              :application_form,
              further_information_request,
              item,
            ],
            status: item.state,
          }
        end
    end

    def can_check_answers?
      further_information_request.items.all?(&:completed?)
    end

    alias_method :can_submit?, :can_check_answers?

    def check_your_answers_fields
      further_information_request
        .items
        .order(:created_at)
        .each_with_object({}) do |item, memo|
          memo[item.id] = {
            title: item_text(item),
            value: item.text? ? item.response : item.document,
            href: [
              :edit,
              :teacher_interface,
              :application_form,
              further_information_request,
              item,
            ],
          }
        end
    end

    private

    attr_reader :current_teacher, :params

    def application_form
      @application_form ||= current_teacher.application_form
    end

    def item_text(item)
      case item.information_type
      when "text"
        I18n.t(
          "teacher_interface.further_information_request.show.failure_reason.#{item.failure_reason_key}",
        )
      when "document"
        "Upload your #{I18n.t("document.document_type.#{item.document.document_type}")} document"
      end
    end
  end
end
