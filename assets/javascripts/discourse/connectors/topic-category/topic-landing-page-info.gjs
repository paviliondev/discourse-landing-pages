import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

const TopicLandingPageInfo = <template>
  {{#if @outletArgs.topic.landing_page_url}}
    <a
      href="/{{@outletArgs.topic.landing_page_url}}"
      title={{i18n "topic.landing_page.link"}}
      class="landing-page-url"
      target="_blank"
      rel="noopener noreferrer"
    >
      {{dIcon "file-lines"}}
      <span>{{i18n "topic.landing_page.link"}}</span>
    </a>
  {{/if}}
</template>;

export default TopicLandingPageInfo;
