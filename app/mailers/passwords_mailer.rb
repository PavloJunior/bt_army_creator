class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Resetowanie hasła", to: user.email_address
  end
end
