# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeacherInterface::UploadsController, type: :controller do
  before { FeatureFlags::FeatureFlag.activate(:service_open) }

  let(:teacher) { create(:teacher) }
  let(:application_form) { create(:application_form, teacher:) }

  before { sign_in teacher, scope: :teacher }

  describe "GET new" do
    let(:document) { create(:document, documentable: application_form) }

    subject(:perform) { get :new, params: { document_id: document.id } }

    include_examples "redirect unless application form is draft"
  end

  describe "POST create" do
    let(:document) { create(:document, documentable: application_form) }

    subject(:perform) { post :create, params: { document_id: document.id } }

    include_examples "redirect unless application form is draft"
  end

  describe "GET delete" do
    let(:document) { create(:document, documentable: application_form) }
    let(:upload) { create(:upload, document:) }

    subject(:perform) do
      get :delete, params: { document_id: document.id, id: upload.id }
    end

    include_examples "redirect unless application form is draft"
  end

  describe "DELETE destroy" do
    let(:document) { create(:document, documentable: application_form) }
    let(:upload) { create(:upload, document:) }

    subject(:perform) do
      get :delete, params: { document_id: document.id, id: upload.id }
    end

    include_examples "redirect unless application form is draft"
  end

  describe "GET show" do
    let(:document) { create(:document, documentable: application_form) }
    let(:upload) { create(:upload, document:) }

    subject(:perform) do
      get :show, params: { document_id: document.id, id: upload.id }
    end

    include_examples "redirect unless application form is draft"

    context "when the upload is present and user is authenticated" do
      it "renders the upload" do
        perform
        expect(response.status).to eq(200)
      end

      it "sends the blob stream" do
        perform
        expect(response.body).to eq(upload.attachment.blob.download)
      end
    end

    context "when the upload is not found" do
      before do
        allow(controller).to receive(:send_blob_stream).and_raise(
          ActiveStorage::FileNotFoundError,
        )
      end

      it "renders not found" do
        perform
        expect(response.status).to eq(404)
      end
    end
  end
end
