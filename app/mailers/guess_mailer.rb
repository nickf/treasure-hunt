class GuessMailer < ApplicationMailer
  def winner
    @guess = params[:guess]
    @treasure = params[:treasure]
    mail(to: @guess.email, subject: 'Congratulations! You Won!')
  end
end
