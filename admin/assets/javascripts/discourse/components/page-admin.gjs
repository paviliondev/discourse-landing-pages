import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { dasherize } from "@ember/string";
import { trustHTML } from "@ember/template";
import AceEditor from "discourse/components/ace-editor";
import { extractError } from "discourse/lib/ajax-error";
import CategoryChooser from "discourse/select-kit/components/category-chooser";
import ComboBox from "discourse/select-kit/components/combo-box";
import GroupChooser from "discourse/select-kit/components/group-chooser";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import LandingPage from "../models/landing-page";

const location = window.location;
const port = location.port ? ":" + location.port : "";
const baseUrl = location.protocol + "//" + location.hostname + port;

export default class PageAdmin extends Component {
  @tracked page;
  @tracked savingPage = false;
  @tracked destroyingPage = false;
  @tracked resultMessage;

  get pages() {
    return this.args.pages;
  }

  get themes() {
    return this.args.themes;
  }

  get groups() {
    return this.args.groups;
  }

  get menus() {
    return this.args.menus;
  }

  get updatingPage() {
    return this.destroyingPage || this.savingPage;
  }

  get hasParent() {
    return !!this.parent;
  }

  updateProps(props = {}) {
    this.args.updatePages(props.pages || this.pages);

    if (props.page) {
      this.page = LandingPage.create(props.page);
    } else {
      this.page = null;
    }
  }

  showErrorMessage(error) {
    this.resultMessage = {
      style: "error",
      icon: "xmark",
      text: extractError(error),
    };
    setTimeout(() => (this.resultMessage = null), 5000);
  }

  get parent() {
    return this.pages.find((page) => page.id === this.page?.parent_id) || null;
  }

  get pagePath() {
    return this.parent ? this.parent.path : this.page?.path;
  }

  get pageUrl() {
    let url = baseUrl;
    if (this.pagePath) {
      url += `/${dasherize(this.pagePath)}`;
    } else {
      url += `/${i18n("admin.landing_pages.page.path.placeholder")}`;
    }
    if (this.hasParent) {
      url += `/1`;
    }
    return url;
  }

  @action
  onChangePath(event) {
    const path = event.target.value;
    if (!this.page.parent_id) {
      this.page.path = path;
    }
  }

  @action
  onChangeParent(pageId) {
    this.page.parent_id = pageId;
  }

  @action
  createPage() {
    this.updateProps({ page: {} });
  }

  @action
  changePage(pageId) {
    if (pageId) {
      LandingPage.find(pageId).then((result) => this.updateProps(result));
    } else {
      this.updateProps();
    }
  }

  @action
  savePage() {
    this.savingPage = true;

    this.page
      .save()
      .then((result) => {
        if (result) {
          this.updateProps(result);
        }
      })
      .catch((error) => this.showErrorMessage(error))
      .finally(() => (this.savingPage = false));
  }

  @action
  destroyPage() {
    const hasChildren = this.pages.find(
      (page) => page.parent_id === this.page.id
    );
    if (hasChildren) {
      this.resultMessage = {
        style: "error",
        icon: "xmark",
        text: i18n("admin.landing_pages.page.destroy.has_children"),
      };
      setTimeout(() => (this.resultMessage = null), 5000);
      return;
    }

    this.destroyingPage = true;

    this.page
      .destroy()
      .then((result) => {
        if (result.success) {
          this.updateProps(result);
        }
      })
      .catch((error) => this.showErrorMessage(error))
      .finally(() => (this.destroyingPage = false));
  }

  @action
  exportPage() {
    this.page
      .export()
      .then((file) => {
        const link = document.createElement("a");
        link.href = URL.createObjectURL(file);
        link.setAttribute(
          "download",
          `discourse-${this.page.name.toLowerCase()}.zip`
        );
        link.click();
      })
      .catch((error) => this.showErrorMessage(error));
  }

  <template>
    <div class="page-controls">
      <div class="page-list-container">
        <ComboBox
          @value={{this.page.id}}
          @content={{this.pages}}
          @onChange={{this.changePage}}
          class="page-select"
          @options={{hash none="admin.landing_pages.page.select"}}
        />

        <DButton
          @action={{this.createPage}}
          @label="admin.landing_pages.create"
          class="page-create"
          @icon="plus"
        />
      </div>
    </div>

    {{#if this.page}}
      <div class="page-header">
        <div class="page-name">
          <span>
            {{#if this.page.name}}
              {{this.page.name}}
            {{else}}
              {{i18n "admin.landing_pages.page.name.label"}}
            {{/if}}
          </span>
        </div>

        <div class="buttons">
          {{#if this.resultMessage}}
            <span class={{this.resultMessage.style}}>
              {{dIcon this.resultMessage.icon}}
              {{trustHTML this.resultMessage.text}}
            </span>
          {{/if}}

          <DConditionalLoadingSpinner
            @condition={{this.updatingPage}}
            @size="small"
          />

          {{#if this.page.id}}
            <DButton
              @action={{this.exportPage}}
              @label="admin.landing_pages.page.export"
              @href={{this.page.exportUrl}}
              @disabled={{this.updatingPage}}
              @icon="upload"
            />

            <DButton
              @action={{this.destroyPage}}
              @label="admin.landing_pages.destroy"
              @disabled={{this.updatingPage}}
              @icon="xmark"
            />
          {{/if}}

          <DButton
            @action={{this.savePage}}
            @label="admin.landing_pages.save"
            class="btn-primary"
            @disabled={{this.updatingPage}}
            @icon="floppy-disk"
          />
        </div>

        <div class="page-url">
          <a href={{this.pageUrl}} target="_blank" rel="noopener noreferrer">
            {{this.pageUrl}}
            {{dIcon "up-right-from-square"}}
          </a>
        </div>
      </div>

      <div class="page-details">
        <div class="control-group">
          <label class="control-label">
            {{i18n "admin.landing_pages.page.name.label"}}
          </label>

          <Input @value={{this.page.name}} class="page-name" />

          <div class="control-instructions">
            {{i18n "admin.landing_pages.page.name.instructions"}}
          </div>
        </div>

        <div class="control-group">
          <label class="control-label">
            {{i18n "admin.landing_pages.page.path.label"}}
          </label>

          <Input
            @value={{readonly this.pagePath}}
            disabled={{this.hasParent}}
            {{on "input" this.onChangePath}}
            class="page-path"
          />

          <div class="control-instructions">
            {{i18n "admin.landing_pages.page.path.instructions"}}
          </div>
        </div>

        <div class="control-group">
          <label class="control-label">
            {{i18n "admin.landing_pages.page.parent.label"}}
          </label>

          <ComboBox
            @value={{this.page.parent_id}}
            @content={{this.pages}}
            @onChange={{this.onChangeParent}}
            class="page-select page-parent"
            @options={{hash none="admin.landing_pages.page.select"}}
          />

          <div class="control-instructions">
            {{i18n "admin.landing_pages.page.parent.instructions"}}
          </div>
        </div>

        <div class="control-group">
          <label class="control-label">
            {{i18n "admin.landing_pages.page.menu.label"}}
          </label>

          <ComboBox
            @content={{this.menus}}
            @value={{this.page.menu}}
            @valueProperty="name"
            @nameProperty="name"
            @onChange={{fn (mut this.page.menu)}}
            class="menu-select"
            @options={{hash none="admin.landing_pages.page.menu.select"}}
          />

          <div class="control-instructions">
            {{i18n "admin.landing_pages.page.menu.instructions"}}
          </div>
        </div>
      </div>

      <div class="page-assets">
        <div class="control-group">
          <label class="control-label">
            {{i18n "admin.landing_pages.page.theme.label"}}
          </label>

          <ComboBox
            @content={{this.themes}}
            @value={{this.page.theme_id}}
            @onChange={{fn (mut this.page.theme_id)}}
            @class="theme-select"
            @options={{hash none="admin.landing_pages.page.theme.select"}}
          />

          <div class="control-instructions">
            {{i18n "admin.landing_pages.page.theme.instructions"}}
          </div>
        </div>

        <div class="control-group">
          <label class="control-label">
            {{i18n "admin.landing_pages.page.groups.label"}}
          </label>

          <GroupChooser
            @class="group-select"
            @content={{this.groups}}
            @value={{this.page.group_ids}}
            @labelProperty="name"
            @onChange={{fn (mut this.page.group_ids)}}
          />

          <div class="control-instructions">
            {{i18n "admin.landing_pages.page.groups.instructions"}}
          </div>
        </div>

        <div class="control-group">
          <label class="control-label">
            {{i18n "admin.landing_pages.page.category.label"}}
          </label>

          <CategoryChooser
            @class="category-select"
            @value={{this.page.category_id}}
            @onChange={{fn (mut this.page.category_id)}}
            @options={{hash
              clearable=true
              disabled=this.hasParent
              none="admin.landing_pages.page.category.select"
            }}
          />

          <div class="control-instructions">
            {{i18n "admin.landing_pages.page.category.instructions"}}
          </div>
        </div>
      </div>

      <div class="page-editor">
        <label class="control-label">
          {{i18n "admin.landing_pages.page.body.label"}}
        </label>

        <div class="control-instructions">
          {{i18n "admin.landing_pages.page.body.instructions"}}
        </div>

        <AceEditor
          @content={{this.page.body}}
          @onChange={{fn (mut this.page.body)}}
          @mode="html"
        />
      </div>
    {{/if}}
  </template>
}
