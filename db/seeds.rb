
if (existing_admin = User.find_by(admin: true))
  puts "Initial admin already exists: #{existing_admin.email_address}"
else
  admin_email = ENV.fetch("INITIAL_ADMIN_EMAIL", "admin@example.com")
  admin_name = ENV.fetch("INITIAL_ADMIN_NAME", "Initial Admin")
  admin_password = ENV.fetch("INITIAL_ADMIN_PASSWORD", "password")

  admin = User.find_or_initialize_by(email_address: admin_email)
  was_new_record = admin.new_record?

  admin.name = admin_name if admin.name.blank?
  admin.admin = true

  if was_new_record || admin.password_digest.blank?
    admin.password = admin_password
    admin.password_confirmation = admin_password
  end

  admin.save!
  puts "#{was_new_record ? 'Created' : 'Updated'} initial admin user: #{admin.email_address}"
end
