# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationFormSearchResultComponent, type: :component do
  subject(:component) { render_inline(described_class.new(application_form)) }

  let(:application_form) do
    create(:application_form, given_names: "Given", family_name: "Family")
  end

  describe "heading text" do
    subject(:text) { component.at_css("h2").text.strip }

    it { is_expected.to eq("Given Family") }
  end

  describe "heading link" do
    subject(:href) { component.at_css("h2 > a")["href"] }

    it do
      is_expected.to eq("/assessor/application_forms/#{application_form.id}")
    end
  end

  describe "description list" do
    subject(:dl) { component.at_css("dl") }

    it { is_expected.to_not be_nil }

    describe "text" do
      subject(:text) { dl.text.strip }

      it { is_expected.to include("Country trained in") }
      it { is_expected.to include("State/territory trained in") }
      it { is_expected.to include("Created on") }
      it { is_expected.to include("Days remaining in SLA") }
      it { is_expected.to include("Assigned to") }
      it { is_expected.to include("Reviewer") }
      it { is_expected.to include("Status") }
      it { is_expected.to include("Notes") }
    end
  end
end
