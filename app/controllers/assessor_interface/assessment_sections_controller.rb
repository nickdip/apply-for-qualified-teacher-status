# frozen_string_literal: true

module AssessorInterface
  class AssessmentSectionsController < BaseController
    def show
      @assessment_section_form =
        assessment_section_form.new(
          user: current_staff,
          **assessment_section_form_class.initial_attributes(
            assessment_section,
          ),
        )
    end

    def update
      @assessment_section_form =
        assessment_section_form.new(
          assessment_section_form_params.merge(
            assessment_section:,
            user: current_staff,
          ),
        )

      if @assessment_section_form.save
        redirect_to [
                      :assessor_interface,
                      assessment_section_view_object.application_form,
                    ]
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def assessment_section_view_object
      @assessment_section_view_object ||=
        AssessmentSectionViewObject.new(params:)
    end

    def assessment_section
      assessment_section_view_object.assessment_section
    end

    def assessment_section_form
      assessment_section_form_class.for_assessment_section(assessment_section)
    end

    def assessment_section_form_class
      if assessment_section.age_range_subjects?
        AgeRangeSubjectsForm
      else
        AssessmentSectionForm
      end
    end

    def assessment_section_form_params
      assessment_section_form.permit_parameters(
        params.require(:assessor_interface_assessment_section_form),
      )
    end
  end
end
