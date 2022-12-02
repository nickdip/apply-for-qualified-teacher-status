# frozen_string_literal: true

module TeacherInterface
  class FurtherInformationRequestsController < BaseController
    include HistoryTrackable

    before_action :load_view_object

    define_history_origins :show
    define_history_checks :edit

    def show
    end

    def edit
    end

    def update
      SubmitFurtherInformationRequest.call(
        further_information_request: @view_object.further_information_request,
        user: current_teacher,
      )

      redirect_to %i[teacher_interface application_form]
    end

    private

    def load_view_object
      @view_object =
        FurtherInformationRequestViewObject.new(current_teacher:, params:)
    end
  end
end
