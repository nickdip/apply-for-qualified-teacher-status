# frozen_string_literal: true

module AssessorInterface
  class ProfessionalStandingRequestsController < BaseController
    before_action :set_variables

    def edit_location
      authorize :note, :edit?

      @form =
        RequestableLocationForm.new(
          requestable:,
          user: current_staff,
          received: requestable.received?,
          location_note: requestable.location_note,
        )
    end

    def update_location
      authorize :note, :update?

      @form =
        RequestableLocationForm.new(
          location_form_params.merge(requestable:, user: current_staff),
        )

      if @form.save
        redirect_to [:assessor_interface, application_form]
      else
        render :edit_location, status: :unprocessable_entity
      end
    end

    private

    def set_variables
      @professional_standing_request = professional_standing_request
      @application_form = application_form
      @assessment = assessment
    end

    def location_form_params
      params.require(:assessor_interface_requestable_location_form).permit(
        :received,
        :location_note,
      )
    end

    def professional_standing_request
      @professional_standing_request ||=
        ProfessionalStandingRequest.joins(
          assessment: :application_form,
        ).find_by(
          assessment_id: params[:assessment_id],
          assessment: {
            application_form_id: params[:application_form_id],
          },
        )
    end

    delegate :application_form, :assessment, to: :professional_standing_request

    alias_method :requestable, :professional_standing_request
  end
end
