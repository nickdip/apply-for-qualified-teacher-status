# frozen_string_literal: true

module AssessorInterface
  class NotesController < BaseController
    before_action :authorize_note

    def new
      @application_form = application_form
      @form = CreateNoteForm.new
    end

    def create
      @application_form = application_form
      @form = CreateNoteForm.new(form_params.merge(application_form:, author:))

      if @form.save
        redirect_to params[:next].presence ||
                      [:assessor_interface, application_form]
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def application_form
      @application_form ||=
        ApplicationForm.find_by!(reference: params[:application_form_reference])
    end

    def author
      @author ||= current_staff
    end

    def form_params
      params.require(:assessor_interface_create_note_form).permit(:text)
    end
  end
end
