# frozen_string_literal: true

# == Schema Information
#
# Table name: assessments
#
#  id                  :bigint           not null, primary key
#  recommendation      :string           default("unknown"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  application_form_id :bigint           not null
#
# Indexes
#
#  index_assessments_on_application_form_id  (application_form_id)
#
# Foreign Keys
#
#  fk_rails_...  (application_form_id => application_forms.id)
#
require "rails_helper"

RSpec.describe Assessment, type: :model do
  subject(:assessment) { create(:assessment) }

  describe "validations" do
    it { is_expected.to have_many(:sections) }

    it { is_expected.to validate_presence_of(:recommendation) }

    it do
      is_expected.to define_enum_for(:recommendation).with_values(
        unknown: "unknown",
        award: "award",
        decline: "decline"
      ).backed_by_column_of_type(:string)
    end
  end

  it "defaults to an unknown recommendation" do
    expect(assessment.unknown?).to be true
  end

  describe "#finished?" do
    subject(:finished?) { assessment.finished? }

    context "with an unknown recommendation" do
      before { assessment.unknown! }
      it { is_expected.to be false }
    end

    context "with an awarded recommendation" do
      before { assessment.award! }
      it { is_expected.to be true }
    end

    context "with an unknown recommendation" do
      before { assessment.decline! }
      it { is_expected.to be true }
    end

    context "with unfinished section assessments" do
      before { assessment.sections.create!(key: :personal_information) }
      it { is_expected.to be false }
    end
  end

  describe "#sections_finished?" do
    subject(:sections_finished?) { assessment.sections_finished? }

    let!(:assessment_section) do
      assessment.sections.create!(key: :personal_information)
    end

    context "with an unknown assessment" do
      it { is_expected.to be false }
    end

    context "with a passed assessment" do
      before { assessment_section.update!(passed: true) }
      it { is_expected.to be true }
    end

    context "with a failed assessment" do
      before do
        assessment_section.update!(
          passed: false,
          selected_failure_reasons: %w[failure_reason]
        )
      end
      it { is_expected.to be true }
    end
  end
end
