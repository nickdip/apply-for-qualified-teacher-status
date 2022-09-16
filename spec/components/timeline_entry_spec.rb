# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimelineEntry::Component, type: :component do
  subject(:component) { render_inline(described_class.new(timeline_event:)) }
  let(:creator) { timeline_event.creator }

  context "assessor assigned" do
    let(:timeline_event) { create(:timeline_event, :assessor_assigned) }
    let(:assignee) { timeline_event.assignee }

    it "describes the event" do
      expect(component.text).to include(
        "#{assignee.name} is assigned as the assessor"
      )
    end

    it "attributes to the creator" do
      expect(component.text).to include(creator.name)
    end
  end

  context "reviewer assigned" do
    let(:timeline_event) { create(:timeline_event, :reviewer_assigned) }
    let(:assignee) { timeline_event.assignee }

    it "describes the event" do
      expect(component.text).to include(
        "#{assignee.name} is assigned as the reviewer"
      )
    end

    it "attributes to the creator" do
      expect(component.text).to include(creator.name)
    end
  end

  context "state changed" do
    let(:timeline_event) { create(:timeline_event, :state_changed) }
    let(:old_state) do
      I18n.t("application_form.status.#{timeline_event.old_state}")
    end
    let(:new_state) do
      I18n.t("application_form.status.#{timeline_event.new_state}")
    end

    it "describes the event" do
      expect(component.text.squish).to include(
        "Status changed from #{old_state} to #{new_state}"
      )
    end

    it "attributes to the creator" do
      expect(component.text).to include(creator.name)
    end
  end

  context "assessment section recorded" do
    let(:timeline_event) do
      create(:timeline_event, :assessment_section_recorded)
    end

    it "describes the event" do
      expect(component.text).to include("Personal Information: Completed")
    end

    it "attributes to the creator" do
      expect(component.text).to include(creator.name)
    end
  end
end
