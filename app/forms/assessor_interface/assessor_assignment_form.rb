class AssessorInterface::AssessorAssignmentForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attr_accessor :application_form, :staff
  attribute :assessor_id, :string

  validates :application_form, :staff, :assessor_id, presence: true

  def save!
    return false unless valid?

    application_form.assessor_id = assessor_id
    application_form.save!
    create_timeline_event!
  end

  private

  def create_timeline_event!
    TimelineEvent.create!(
      application_form:,
      event_type: "assessor_assigned",
      creator: staff,
      assignee_id: assessor_id
    )
  end
end
