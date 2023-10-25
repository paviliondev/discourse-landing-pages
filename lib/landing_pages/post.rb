# frozen_string_literal: true
class ::LandingPages::Post
  def self.html(post, remove_topic_image: true)
    fragment = Nokogiri::HTML5.fragment(post.cooked)

    if remove_topic_image && topic_image_sha1 = post.topic&.image_upload&.sha1
      if image_node = fragment.css("a[href*='#{topic_image_sha1}']").first
        image_node.parent.remove
      end
    end

    fragment.to_html
  end
end
