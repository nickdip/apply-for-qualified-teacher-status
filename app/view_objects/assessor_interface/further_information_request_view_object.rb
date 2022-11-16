# frozen_string_literal: true

class AssessorInterface::FurtherInformationRequestViewObject
  def initialize(params:)
    @params = params
  end

  def further_information_request
    @further_information_request ||=
      FurtherInformationRequest
        .joins(assessment: :application_form)
        .received
        .where(
          assessment_id: params[:assessment_id],
          assessment: {
            application_form_id: params[:application_form_id],
          },
        )
        .find(params[:id])
  end

  delegate :assessment, to: :further_information_request
  delegate :application_form, to: :assessment

  def check_your_answers_fields
    further_information_request
      .items
      .order(:created_at)
      .each_with_object({}) do |item, memo|
        memo[item.id] = {
          title: item_text(item),
          value: item.text? ? item.response : item.document,
        }
      end
  end

  private

  attr_reader :params

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
