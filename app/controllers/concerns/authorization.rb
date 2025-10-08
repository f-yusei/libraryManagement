module Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :admin?
  end

  class_methods do
    def admin_only(**options)
      before_action :require_admin!, **options
    end
  end

  private
    def admin?
      current_user&.admin?
    end

    def require_admin!
      return if admin?

      redirect_to root_path, flash: { danger: "アクセス権限がありません" }
    end
end
