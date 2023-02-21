# frozen_string_literal: true

RSpec.shared_examples "a requestable" do
  it do
    is_expected.to define_enum_for(:state).with_values(
      requested: "requested",
      received: "received",
      expired: "expired",
    ).backed_by_column_of_type(:string)
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:state) }

    it { is_expected.to_not validate_presence_of(:received_at) }

    context "when received" do
      before { subject.state = "received" }

      it { is_expected.to validate_presence_of(:received_at) }
    end

    context "when reviewed" do
      before { subject.passed = [true, false].sample }

      it { is_expected.to validate_presence_of(:reviewed_at) }
    end
  end

  describe "#received!" do
    let(:call) { subject.received! }

    it "changes the state" do
      expect { call }.to change(subject, :received?).from(false).to(true)
    end

    it "sets the received at date" do
      freeze_time do
        expect { call }.to change(subject, :received_at).from(nil).to(
          Time.zone.now,
        )
      end
    end
  end

  [true, false].each do |passed|
    describe "#reviewed!(#{passed})" do
      let(:call) { subject.reviewed!(passed) }

      it "changes passed field" do
        expect { call }.to change(subject, :passed).from(nil).to(passed)
      end

      it "sets the reviewed at date" do
        freeze_time do
          expect { call }.to change(subject, :reviewed_at).from(nil).to(
            Time.zone.now,
          )
        end
      end
    end
  end

  describe "#status" do
    it "is the same as state when passed is nil and state is defined" do
      subject.passed = nil
      subject.state = "received"
      expect(subject.status).to eq("received")
    end

    it "is accepted when passed is true" do
      subject.passed = true
      expect(subject.status).to eq("accepted")
    end

    it "is rejected when passed is false" do
      subject.passed = false
      expect(subject.status).to eq("rejected")
    end
  end
end
