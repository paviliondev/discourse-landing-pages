# frozen_string_literal: true
module UserEmailJobLandingPagesExtension
  def always_email_regular?(user, type)
    super || begin
      return false unless @skip_context[:post_id] && post = Post.find_by(id: @skip_context[:post_id])
      post.topic&.category&.landing_page_id.present?
    end
  end
end
