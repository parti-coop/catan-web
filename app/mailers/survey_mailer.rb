class SurveyMailer < ApplicationMailer
  def self.deliver_all_later_on_closed(survey)
    return if survey.blank?

    survey.post.messagable_users.each do |user|
      on_closed(user.id, survey.id).deliver_later
    end
  end

  def on_closed(user_id, survey_id)
    @survey = Survey.find_by(id: survey_id)
    @user = User.find_by(id: user_id)
    return if @survey.blank? or @user.blank? or !@user.enable_mailing?

    mail(to: @user.email,
         subject: "[빠띠] #{@survey.post.user.nickname}님이 올린 설문에 결과가 나왔습니다 : #{view_context.excerpt(@survey.post.specific_desc, length: 50)}")
  end
end