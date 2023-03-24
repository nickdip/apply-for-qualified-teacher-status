# frozen_string_literal: true

# == Schema Information
#
# Table name: professional_standing_requests
#
#  id                    :bigint           not null, primary key
#  failure_assessor_note :string           default(""), not null
#  location_note         :text             default(""), not null
#  passed                :boolean
#  ready_for_review      :boolean          default(FALSE), not null
#  received_at           :datetime
#  reviewed_at           :datetime
#  state                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  assessment_id         :bigint           not null
#
# Indexes
#
#  index_professional_standing_requests_on_assessment_id  (assessment_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#
require "rails_helper"

RSpec.describe ProfessionalStandingRequest, type: :model do
  it_behaves_like "a requestable" do
    subject { create(:professional_standing_request, :receivable) }
  end

  describe "#expires_after" do
    let(:professional_standing_request) do
      create(
        :professional_standing_request,
        assessment:
          create(
            :assessment,
            application_form:
              create(
                :application_form,
                teaching_authority_provides_written_statement:,
              ),
          ),
      )
    end

    subject(:expires_after) { professional_standing_request.expires_after }

    context "when the teaching authority provides the written statement" do
      let(:teaching_authority_provides_written_statement) { true }
      it { is_expected.to eq(18.weeks) }
    end

    context "when the applicant provides the written statement" do
      let(:teaching_authority_provides_written_statement) { false }
      it { is_expected.to eq(6.weeks) }
    end
  end
end
