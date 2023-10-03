# frozen_string_literal: true
class LandingPages::InvalidAccess < StandardError
end
class LandingPages::InvalidParameters < StandardError
end

class LandingPages::LandingController < ::ActionController::Base
  VIEW_PATH ||= Rails.root.join("plugins", "discourse-landing-pages", "app", "views")

  prepend_view_path(VIEW_PATH)
  helper ::EmojiHelper
  helper ::ApplicationHelper
  helper LandingHelper
  include CurrentUser

  before_action :find_global, only: [:show]
  before_action :find_page, only: %i[show topic_list]
  before_action :check_access, only: [:show]
  before_action :find_menu, only: [:show]
  before_action :find_assets, only: [:show]
  before_action :load_theme, only: [:show]
  before_action :ensure_can_change_subscription, only: [:subscription]
  before_action :find_category_user, only: [:subscription]

  helper_method :list_item_html, :list_topics

  def show
    if @page.present?
      @page_title = SiteSetting.title + " | #{@page.name}"
      @classes = @page.name.parameterize
      @theme_id = @page.theme_id

      if @global.present?
        @scripts = @global.scripts if @global.scripts.present?
        @header = @global.header if @global.header.present?
        @footer = @global.footer if @global.footer.present?
      end

      render inline: @page.body, layout: "landing"
    else
      redirect_to path("/")
    end
  end

  def contact
    Jobs.enqueue(
      :send_contact_email,
      from: contact_params[:email],
      message: contact_params[:message],
    )

    respond_to do |format|
      format.html
      format.js { head :ok }
    end
  end

  def subscription
    subscribed =
      @category_user.notification_level >= CategoryUser.notification_levels[:watching_first_post]
    new_subscribed = ActiveModel::Type::Boolean.new.cast(subscription_params[:subscribed])

    if new_subscribed != subscribed
      level_name = new_subscribed ? :watching_first_post : :regular
      level = CategoryUser.notification_levels[level_name]
      user = @category_user.user
      category_id = @category_user.category_id

      CategoryUser.set_notification_level_for_category(user, level, category_id)
    end

    respond_to do |format|
      format.html
      format.js { head :ok }
    end
  end

  def topic_list
    topics = list_topics(topic_list_params[:opts], topic_list_params[:list_opts])
    topics_html = list_item_html(topics, topic_list_params[:item_opts])

    render json: { topics_html: topics_html }
  end

  rescue_from LandingPages::InvalidAccess do |e|
    @group = Group.find(@page.group_ids.first)
    @page_title = I18n.t("page_forbidden.title")
    @classes = "forbidden"
    render status: 403, layout: "landing", formats: [:html], template: "/exceptions/not_found"
  end

  private

  def find_global
    @global = LandingPages::Global.find
  end

  def find_page
    if params[:path] && params[:param]
      @page = LandingPages::Page.find_child_page(params[:path])
    elsif params[:path]
      @page = LandingPages::Page.find_by("path", params[:path])
    elsif params[:page_id]
      @page = LandingPages::Page.find(params[:page_id])
    end

    raise LandingPages::InvalidParameters.new unless @page.present?
  end

  def find_menu
    @menu = LandingPages::Menu.find_by("name", @page.menu) if @page.menu.present?
  end

  def find_assets
    if @page.assets.present?
      @page.assets.each do |asset_name|
        if asset = LandingPages::Asset.find_by("name", asset_name)
          instance_variable_set("@#{asset.name}", asset)
        end
      end
    end
  end

  def check_access
    if @page.group_ids.present? && !@page.group_ids.include?(Group::AUTO_GROUPS[:everyone]) &&
         (!current_user || (current_user.groups.map(&:id) & @page.group_ids).empty?)
      raise LandingPages::InvalidAccess.new
    end
  end

  def load_theme
    if @page.present? && @page.theme_id.present?
      @theme_id = request.env[:resolved_theme_id] = @page.theme_id
    end
  end

  def contact_params
    params.require(:email)
    params.require(:message)

    result = params.permit(:email, :message)

    unless params[:email] =~ EmailValidator.email_regex
      raise LandingPages::InvalidParameters.new(:email)
    end

    result
  end

  def subscription_params
    params.require(:category_id)
    params.permit(:category_id, :subscribed)
  end

  def topic_list_params
    params.require(:list_opts)
    permitted =
      params.permit(
        list_opts: [:category, :page, :per_page, :no_definitions, except_topic_ids: []],
        item_opts: %i[classes excerpt_length include_avatar profile_details avatar_size],
        opts: {
        },
      )

    result = {}
    %i[opts list_opts item_opts].each do |key|
      hash = permitted[key].to_h.symbolize_keys
      hash.each do |k, v|
        hash[k] = v.to_i if %i[page per_page excerpt_length avatar_size].include? k
        hash[k] = v === "true" if %i[no_definitions include_avatar profile_details].include? k
        hash[k] = v.map(&:to_i) if [:except_topic_ids].include? k
      end
      result[key] = hash
    end

    if result[:list_opts][:category]
      category = Category.find_by_slug_path_with_id(result[:list_opts][:category])
      raise Discourse::NotFound.new("category not found") if category.nil?
      result[:list_opts][:category] = category.id
    end

    result
  end

  def ensure_can_change_subscription
    raise Discourse::NotLoggedIn.new unless current_user.present?
  end

  def find_category_user
    @category_user =
      CategoryUser.find_by(category_id: subscription_params[:category_id], user_id: current_user.id)

    if !@category_user
      @category_user =
        CategoryUser.create!(
          category_id: subscription_params[:category_id],
          user_id: current_user.id,
          notification_level: CategoryUser.notification_levels[:regular],
        )
    end

    raise Discourse::InvalidParameters.new unless @category_user
  end

  def list_item_html(topics, item_opts)
    html = ""
    topics.each do |topic|
      html +=
        render_to_string(
          partial: "topic_list_item",
          locals: { topic: topic, topic_url: "#{@page.path}/#{topic.slug}" }.merge(item_opts),
        )
    end
    html
  end

  def list_topics(opts, list_opts)
    query = TopicQuery.new(current_user, list_opts)

    group = Group.find_by(name: opts[:group_name]) if opts[:group_name]

    user = User.find_by(username: opts[:username]) if opts[:username]

    if user
      list = query.list_topics_by(user)
    elsif group
      list = query.list_group_topics(group)
    else
      list = query.list_latest
    end

    list.topics
  end
end
