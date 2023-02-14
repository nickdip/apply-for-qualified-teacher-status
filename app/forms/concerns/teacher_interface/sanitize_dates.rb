# frozen_string_literal: true

module TeacherInterface
  module SanitizeDates
    extend ActiveSupport::Concern

    included do
      def sanitize_dates!(*dates)
        today = Time.zone.now

        dates.each do |date|
          next if date.nil? || date[1].blank? || date[2].blank?

          date[2] = 1 if date[2].to_i < 1 || date[2].to_i > 12

          date[1] = today.year if date[1] > today.year || date[1] < 1900
        end
      end
    end
  end
end
