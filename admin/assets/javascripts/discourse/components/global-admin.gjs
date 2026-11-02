import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { trustHTML } from "@ember/template";
import ValueList from "discourse/admin/components/value-list";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import LandingPageGlobal from "../models/landing-page-global";
import JsonEditor from "./json-editor";

export default class GlobalAdmin extends Component {
  @tracked global;
  @tracked scripts;
  @tracked jsonHeader;
  @tracked jsonFooter;
  @tracked savingGlobal = false;
  @tracked destroyingGlobal = false;
  @tracked jsonHeaderError;
  @tracked jsonFooterError;
  @tracked resultIcon;

  constructor() {
    super(...arguments);
    this.global = this.args.global;
    this.initializeProps();
  }

  initializeProps() {
    this.scripts = this.global?.scripts;
    this.jsonHeader = JSON.stringify(this.global?.header || undefined, null, 4);
    this.jsonFooter = JSON.stringify(this.global?.footer || undefined, null, 4);
  }

  get updatingGlobal() {
    return this.destroyingGlobal || this.savingGlobal;
  }

  @action
  saveGlobal() {
    this.savingGlobal = true;
    this.jsonHeaderError = null;
    this.jsonFooterError = null;

    let header;
    try {
      header = JSON.parse(this.jsonHeader || "null");
    } catch (e) {
      this.jsonHeaderError = e.message;
    }

    let footer;
    try {
      footer = JSON.parse(this.jsonFooter || "null");
    } catch (e) {
      this.jsonFooterError = e.message;
    }

    if (this.jsonHeaderError || this.jsonFooterError) {
      this.savingGlobal = false;
      this.resultIcon = "xmark";
      setTimeout(() => (this.resultIcon = null), 10000);
      return;
    }

    const data = {
      global: {
        scripts: this.scripts,
        header,
        footer,
      },
    };

    LandingPageGlobal.save(data)
      .then((result) => {
        if (result.success) {
          this.resultIcon = "check";
          this.global = data.global;
          this.initializeProps();
        } else {
          this.resultIcon = "xmark";
        }
        setTimeout(() => (this.resultIcon = null), 10000);
      })
      .finally(() => (this.savingGlobal = false));
  }

  @action
  destroyGlobal() {
    this.destroyingGlobal = true;

    LandingPageGlobal.destroy()
      .then((result) => {
        if (result.success) {
          this.resultIcon = "check";
          this.global = {};
          this.initializeProps();
        } else {
          this.resultIcon = "xmark";
        }
        setTimeout(() => (this.resultIcon = null), 10000);
      })
      .finally(() => (this.destroyingGlobal = false));
  }

  <template>
    <div class="page-header">
      <div class="page-name">
        <span>{{i18n "admin.landing_pages.global.label"}}</span>
      </div>

      <div class="buttons">
        {{#if this.resultIcon}}
          {{dIcon this.resultIcon}}
        {{/if}}

        <DConditionalLoadingSpinner
          @condition={{this.updatingGlobal}}
          @size="small"
        />

        <DButton
          @action={{this.destroyGlobal}}
          @label="admin.landing_pages.destroy"
          @disabled={{this.updatingGlobal}}
          @icon="xmark"
        />

        <DButton
          @action={{this.saveGlobal}}
          @label="admin.landing_pages.save"
          class="btn-primary"
          @disabled={{this.updatingGlobal}}
          @icon="floppy-disk"
        />
      </div>
    </div>

    <div class="page-global">
      <div class="control-group">
        <label class="control-label">
          {{i18n "admin.landing_pages.global.scripts.label"}}
        </label>

        <ValueList @values={{this.scripts}} @inputType="array" />

        <div class="control-instructions">
          {{trustHTML (i18n "admin.landing_pages.global.scripts.description")}}
        </div>
      </div>

      <div class="control-group global-editor">
        <label class="control-label">
          {{i18n "admin.landing_pages.global.header.label"}}
        </label>

        <div class="control-instructions">
          {{trustHTML (i18n "admin.landing_pages.global.header.description")}}
        </div>

        <JsonEditor @content={{this.jsonHeader}} />
        {{#if this.jsonHeaderError}}
          <span class="validation-error">
            {{dIcon "xmark"}}
            {{i18n
              "admin.landing_pages.global.header.error"
              error=this.jsonHeaderError
            }}
          </span>
        {{/if}}
      </div>

      <div class="control-group global-editor">
        <label class="control-label">
          {{i18n "admin.landing_pages.global.footer.label"}}
        </label>

        <div class="control-instructions">
          {{trustHTML (i18n "admin.landing_pages.global.footer.description")}}
        </div>

        <JsonEditor @content={{this.jsonFooter}} />
        {{#if this.jsonFooterError}}
          <span class="validation-error">
            {{dIcon "xmark"}}
            {{i18n
              "admin.landing_pages.global.footer.error"
              error=this.jsonFooterError
            }}
          </span>
        {{/if}}
      </div>
    </div>
  </template>
}
