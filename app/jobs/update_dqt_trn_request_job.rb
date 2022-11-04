# frozen_string_literal: true

class UpdateDQTTRNRequestJob < ApplicationJob
  class StillPending < StandardError
  end

  retry_on Faraday::Error, wait: :exponentially_longer, attempts: 3
  retry_on StillPending, wait: 30.minutes, attempts: 7 * 24 * 2 # 1 week

  def perform(dqt_trn_request)
    return if dqt_trn_request.complete?

    response =
      if dqt_trn_request.initial?
        DQT::Client::CreateTRNRequest.call(
          request_id: dqt_trn_request.request_id,
          application_form: dqt_trn_request.application_form,
        )
      else
        DQT::Client::ReadTRNRequest.call(request_id: dqt_trn_request.request_id)
      end

    dqt_trn_request.pending! if dqt_trn_request.initial?

    if (trn = response[:trn]).present?
      AwardQTS.call(
        application_form: dqt_trn_request.application_form,
        user: "DQT",
        trn:,
      )

      dqt_trn_request.complete!
    end

    raise StillPending if dqt_trn_request.pending?
  end
end
