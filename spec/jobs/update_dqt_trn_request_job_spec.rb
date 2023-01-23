# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdateDQTTRNRequestJob, type: :job do
  describe "#perform" do
    subject(:perform) { described_class.new.perform(dqt_trn_request) }

    let(:application_form) { dqt_trn_request.application_form }
    let(:teacher) { application_form.teacher }

    let(:perform_rescue_exception) do
      perform
    rescue StandardError
    end

    context "with an initial request" do
      let(:dqt_trn_request) { create(:dqt_trn_request, :initial) }

      context "with a successful response" do
        before do
          expect(DQT::Client::CreateTRNRequest).to receive(:call).and_return(
            { potential_duplicate: false, trn: "abcdef" },
          )
        end

        it "marks the request as complete" do
          expect { perform }.to change(dqt_trn_request, :complete?).to(true)
        end

        it "sets potential duplicate" do
          expect { perform }.to change(
            dqt_trn_request,
            :potential_duplicate,
          ).to(false)
        end

        it "awards QTS" do
          expect(AwardQTS).to receive(:call).with(
            application_form:,
            user: "DQT",
            trn: "abcdef",
          )
          perform
        end

        it "doesn't queue another job" do
          expect { perform }.to_not have_enqueued_job(UpdateDQTTRNRequestJob)
        end
      end

      context "with a failure response" do
        before do
          expect(DQT::Client::CreateTRNRequest).to receive(:call).and_raise(
            Faraday::BadRequestError.new(StandardError.new),
          )
        end

        it "leaves the request as initial" do
          expect { perform_rescue_exception }.to_not change(
            dqt_trn_request,
            :state,
          )
        end

        it "leaves the potential duplicate" do
          expect { perform_rescue_exception }.to_not change(
            dqt_trn_request,
            :potential_duplicate,
          )
        end

        it "doesn't award QTS" do
          expect(AwardQTS).to_not receive(:call)
          perform_rescue_exception
        end

        it "doesn't change the state" do
          expect { perform_rescue_exception }.to_not change(
            application_form,
            :state,
          )
        end

        it "raises the error" do
          expect { perform }.to raise_error(Faraday::BadRequestError)
        end
      end

      context "with a potential duplicate response" do
        before do
          expect(DQT::Client::CreateTRNRequest).to receive(:call).and_return(
            { potential_duplicate: true },
          )
        end

        it "marks the request as pending" do
          expect { perform }.to change(dqt_trn_request, :pending?).to(true)
        end

        it "sets potential duplicate" do
          expect { perform }.to change(
            dqt_trn_request,
            :potential_duplicate,
          ).to(true)
        end

        it "doesn't award QTS" do
          expect(AwardQTS).to_not receive(:call)
          perform
        end

        it "changes the state" do
          expect { perform }.to change(application_form, :state).to(
            "potential_duplicate_in_dqt",
          )
        end

        it "queues another job" do
          expect { perform }.to have_enqueued_job(UpdateDQTTRNRequestJob)
        end
      end
    end

    context "with a pending request" do
      let(:dqt_trn_request) { create(:dqt_trn_request, :pending) }

      context "with a successful response" do
        before do
          expect(DQT::Client::ReadTRNRequest).to receive(:call).and_return(
            { potential_duplicate: false, trn: "abcdef" },
          )
        end

        it "marks the request as complete" do
          expect { perform }.to change(dqt_trn_request, :complete?).to(true)
        end

        it "sets potential duplicate" do
          expect { perform }.to change(
            dqt_trn_request,
            :potential_duplicate,
          ).to(false)
        end

        it "awards QTS" do
          expect(AwardQTS).to receive(:call).with(
            application_form:,
            user: "DQT",
            trn: "abcdef",
          )
          perform
        end

        it "doesn't queue another job" do
          expect { perform }.to_not have_enqueued_job(UpdateDQTTRNRequestJob)
        end
      end

      context "with a failure response" do
        before do
          expect(DQT::Client::ReadTRNRequest).to receive(:call).and_raise(
            Faraday::BadRequestError.new(StandardError.new),
          )
        end

        it "leaves the request as pending" do
          expect { perform_rescue_exception }.to_not change(
            dqt_trn_request,
            :state,
          )
        end

        it "leaves the potential duplicate" do
          expect { perform_rescue_exception }.to_not change(
            dqt_trn_request,
            :potential_duplicate,
          )
        end

        it "doesn't award QTS" do
          expect(AwardQTS).to_not receive(:call)
          perform_rescue_exception
        end

        it "doesn't change the state" do
          expect { perform_rescue_exception }.to_not change(
            application_form,
            :state,
          )
        end

        it "raises the error" do
          expect { perform }.to raise_error(Faraday::BadRequestError)
        end
      end

      context "with a potential duplicate response" do
        before do
          expect(DQT::Client::ReadTRNRequest).to receive(:call).and_return(
            { potential_duplicate: true },
          )
        end

        it "leaves the request as pending" do
          expect { perform_rescue_exception }.to_not change(
            dqt_trn_request,
            :state,
          )
        end

        it "sets potential duplicate" do
          expect { perform }.to change(
            dqt_trn_request,
            :potential_duplicate,
          ).to(true)
        end

        it "doesn't award QTS" do
          expect(AwardQTS).to_not receive(:call)
          perform
        end

        it "changes the state" do
          expect { perform }.to change(application_form, :state).to(
            "potential_duplicate_in_dqt",
          )
        end

        it "queues another job" do
          expect { perform }.to have_enqueued_job(UpdateDQTTRNRequestJob)
        end
      end
    end

    context "with a complete request" do
      let(:dqt_trn_request) { create(:dqt_trn_request, :complete) }

      it "leaves the request as pending" do
        expect { perform_rescue_exception }.to_not change(
          dqt_trn_request,
          :state,
        )
      end

      it "leaves the potential duplicate" do
        expect { perform_rescue_exception }.to_not change(
          dqt_trn_request,
          :potential_duplicate,
        )
      end

      it "doesn't award QTS" do
        expect(AwardQTS).to_not receive(:call)
        perform
      end

      it "doesn't change the state" do
        expect { perform }.to_not change(application_form, :state)
      end

      it "doesn't queue another job" do
        expect { perform }.to_not have_enqueued_job(UpdateDQTTRNRequestJob)
      end
    end
  end
end
