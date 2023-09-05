# frozen_string_literal: true

class SupportInterface::FeatureFlagPolicy < ApplicationPolicy
  def index?
    user.support_console_permission?
  end

  def activate?
    user.support_console_permission?
  end

  def deactivate?
    user.support_console_permission?
  end
end
