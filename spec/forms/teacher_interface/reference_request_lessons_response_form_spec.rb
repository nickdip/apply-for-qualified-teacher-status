# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeacherInterface::ReferenceRequestLessonsResponseForm,
               type: :model do
  let(:reference_request) { create(:reference_request) }

  subject(:form) { described_class.new(reference_request:, lessons_response:) }

  describe "validations" do
    let(:lessons_response) { "" }

    it { is_expected.to validate_presence_of(:reference_request) }
    it { is_expected.to allow_values(true, false).for(:lessons_response) }
  end

  describe "#save" do
    subject(:save) { form.save(validate: true) }

    let(:lessons_response) { "true" }

    it "saves the application form" do
      expect { save }.to change(reference_request, :lessons_response).to(true)
    end
  end
end
