# frozen_string_literal: true

class PersonasController < ApplicationController
  include EligibilityCurrentNamespace

  before_action :ensure_feature_active
  before_action :load_teacher_personas, :load_eligible_personas, only: :index

  def index
    @staff = Staff.all

    @reference_requests =
      ReferenceRequest.states.values.filter_map do |state|
        ReferenceRequest.find_by(state:)
      end
  end

  def eligible_sign_in
    region = Region.find(params[:id])

    eligibility_check =
      EligibilityCheck.create!(
        completed_at: Time.zone.now,
        country_code: region.country.code,
        degree: true,
        free_of_sanctions: true,
        qualification: true,
        region:,
        teach_children: true,
        work_experience: "over_20_months",
      )

    session[:eligibility_check_id] = eligibility_check.id

    redirect_to %i[eligibility_interface eligible]
  end

  def staff_sign_in
    staff = Staff.find(params[:id])
    sign_in_and_redirect(staff)
  end

  def teacher_sign_in
    teacher = Teacher.find(params[:id])
    sign_in_and_redirect(teacher)
  end

  protected

  def after_sign_in_path_for(resource)
    case resource
    when Staff
      :assessor_interface_root
    when Teacher
      :teacher_interface_root
    end
  end

  private

  def ensure_feature_active
    unless FeatureFlags::FeatureFlag.active?(:personas)
      flash[:warning] = "Personas feature not active."
      redirect_to :root
    end
  end

  ELIGIBLE_PERSONAS =
    %w[online written none] # sanction_check
      .product(
        %w[online written none], # status_check
        [true, false], # application_form_skip_work_history
        [true, false], # teaching_authority_provides_written_statement
        [true, false], # reduced_evidence_accepted
      )
      .map do |persona|
        {
          sanction_check: persona[0],
          status_check: persona[1],
          application_form_skip_work_history: persona[2],
          teaching_authority_provides_written_statement: persona[3],
          reduced_evidence_accepted: persona[4],
        }
      end

  def load_eligible_personas
    all_regions = Region.includes(:country).order(:id)

    @eligible_personas =
      ELIGIBLE_PERSONAS.filter_map do |persona|
        found_region =
          all_regions.find do |region|
            region.status_check == persona[:status_check] &&
              region.sanction_check == persona[:sanction_check] &&
              region.application_form_skip_work_history ==
                persona[:application_form_skip_work_history] &&
              region.teaching_authority_provides_written_statement ==
                persona[:teaching_authority_provides_written_statement] &&
              region.reduced_evidence_accepted ==
                persona[:reduced_evidence_accepted]
          end

        persona.merge(region: found_region) if found_region
      end
  end

  TEACHER_PERSONAS =
    %w[online written none]
      .product(
        %w[online written none],
        %w[draft submitted waiting_on awarded declined],
        [true, false],
      )
      .tap { |personas| personas.insert(2, *personas.slice!(8, 2)) }
      .map do |status_check, sanction_check, status, created_under_new_regulations|
        {
          status_check:,
          sanction_check:,
          status:,
          created_under_new_regulations:,
        }
      end

  def load_teacher_personas
    all_teachers =
      Teacher.includes(
        application_forms: {
          region: :country,
          documents: :uploads,
          qualifications: {
            documents: :uploads,
          },
          work_histories: [],
        },
      ).order(:id)

    @teacher_personas =
      TEACHER_PERSONAS.filter_map do |persona|
        found_teacher =
          all_teachers.find do |teacher|
            application_form = teacher.application_form
            next false if application_form.blank?

            region = application_form.region

            region.status_check == persona[:status_check] &&
              region.sanction_check == persona[:sanction_check] &&
              application_form.status == persona[:status] &&
              application_form.created_under_new_regulations? ==
                persona[:created_under_new_regulations]
          end

        persona.merge(teacher: found_teacher) if found_teacher
      end
  end
end
