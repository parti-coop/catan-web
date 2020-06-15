class PinMailer < ApplicationMailer
  def notify(sender_id, recipient_id, post_id)
    @sender = User.find_by id: sender_id
    @recipient = User.find_by id: recipient_id
    @post = Post.find_by id: post_id
    return if @sender.blank? or @recipient.blank? or @post.blank?
    return unless @recipient.enable_mailing_pin?
    truncated_body = @post.specific_desc_striped_tags(20)
    mail(from: build_from(@sender),
      to: @recipient.email, reply_to: @sender.email,
      subject: "[#{I18n.t('labels.app_name_human')}] #{@sender.nickname}님이 게시글을 고정했습니다 : #{truncated_body}")
  end
end
