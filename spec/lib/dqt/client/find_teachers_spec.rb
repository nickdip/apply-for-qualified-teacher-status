# frozen_string_literal: true

require "rails_helper"

RSpec.describe DQT::Client::FindTeachers do
  let(:application_form) do
    create(:application_form, :submitted, :with_personal_information)
  end
  let(:request_params) do
    {
      dateOfBirth: application_form.date_of_birth.iso8601.to_s,
      emailAddress: application_form.teacher.email,
      firstName: application_form.given_names.split(" ").first,
      lastName: application_form.family_name,
    }
  end

  subject(:call) { described_class.call(application_form:) }

  context "with a successful response" do
    before do
      stub_request(
        :get,
        "https://test-teacher-qualifications-api.education.gov.uk/v2/teachers/find?#{request_params.to_query}",
      ).with(headers: { "Authorization" => "Bearer test-api-key" }).to_return(
        status: 200,
        body: { results: [request_params.merge(trn: "1234567")] }.to_json,
        headers: {
          "Content-Type" => "application/json",
        },
      )
    end

    it do
      is_expected.to eq(
        [
          {
            date_of_birth: application_form.date_of_birth.iso8601.to_s,
            email_address: application_form.teacher.email,
            first_name: application_form.given_names.split(" ").first,
            last_name: application_form.family_name,
            trn: "1234567",
          },
        ],
      )
    end
  end

  context "with an error response" do
    before do
      stub_request(
        :get,
        "https://test-teacher-qualifications-api.education.gov.uk/v2/teachers/find?#{request_params.to_query}",
      ).with(headers: { "Authorization" => "Bearer test-api-key" }).to_return(
        status: 500,
        headers: {
          "Content-Type" => "application/json",
        },
      )
    end

    it { is_expected.to eq([]) }
  end
end
