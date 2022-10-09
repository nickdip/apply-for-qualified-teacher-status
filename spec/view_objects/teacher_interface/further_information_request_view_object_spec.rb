# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeacherInterface::FurtherInformationRequestViewObject do
  subject(:view_object) do
    described_class.new(
      current_teacher:,
      params: ActionController::Parameters.new(params),
    )
  end

  let(:current_teacher) { create(:teacher, :confirmed) }
  let(:application_form) { create(:application_form, teacher: current_teacher) }
  let(:further_information_request) do
    create(
      :further_information_request,
      :requested,
      assessment: create(:assessment, application_form:),
    )
  end
  let(:params) do
    {
      id: further_information_request.id,
      application_form_id: application_form.id,
    }
  end

  describe "#task_items" do
    let!(:text_item) do
      create(
        :further_information_request_item,
        :with_text_response,
        further_information_request:,
      )
    end
    let!(:document_item) do
      create(
        :further_information_request_item,
        :with_document_response,
        further_information_request:,
        document: create(:document, :identification_document),
      )
    end

    subject(:task_items) { view_object.task_items }

    it do
      is_expected.to eq(
        [
          {
            key: text_item.id,
            text: "Tell us more about the subjects you can teach",
            href: [
              :edit,
              :teacher_interface,
              :application_form,
              further_information_request,
              text_item,
            ],
            status: :not_started,
          },
          {
            key: document_item.id,
            text: "Upload your identity document",
            href: [
              :edit,
              :teacher_interface,
              :application_form,
              further_information_request,
              document_item,
            ],
            status: :not_started,
          },
        ],
      )
    end
  end

  describe "#can_check_answers?" do
    subject(:can_check_answers?) { view_object.can_check_answers? }

    context "with uncomplete items" do
      before do
        create(:further_information_request_item, further_information_request:)
      end

      it { is_expected.to be false }
    end

    context "with complete items" do
      before do
        create(
          :further_information_request_item,
          :with_text_response,
          :completed,
          further_information_request:,
        )
      end

      it { is_expected.to be true }
    end
  end
end
