module ApplicationFormStatusTag
  class Component < ViewComponent::Base
    attr_reader :class_context

    def initialize(key:, status:, class_context:)
      super
      @key = key
      @status = status.to_sym
      @class_context = class_context
    end

    def id
      "#{@key}-status"
    end

    def text
      I18n.t("application_form.status.#{@status}")
    end

    COLOURS = {
      not_started: "grey",
      in_progress: "blue",
      initial_assessment: "blue",
      request_further_information: "yellow",
      received_further_information: "purple",
      awarded: "green",
      declined: "red",
      draft: "grey",
      submitted: "grey",
      cannot_start_yet: "grey"
    }.freeze

    def colour
      COLOURS[@status]
    end
  end
end
