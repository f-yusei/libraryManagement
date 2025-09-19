Rails.application.config.to_prepare do
  if Rails.env.production?
    User.find_or_create_by!(email_address: "alice@example.com") do |user|
      user.name = "Alice"
      user.password = "password"
      user.password_confirmation = "password"
      user.admin = true
    end
  end
end
