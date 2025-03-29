import Component from "@ember/component";
import { action } from "@ember/object";
import discourseComputed from "discourse-common/utils/decorators";
import { notEmpty, or } from "@ember/object/computed";
import { dasherize } from "@ember/string";
import LandingPage from "../models/landing-page";
import { extractError } from "discourse/lib/ajax-error";
import I18n from "I18n";

const location = window.location;
const port = location.port ? ":" + location.port : "";
const baseUrl = location.protocol + "//" + location.hostname + port;

export default Component.extend({
  updatingPage: or("destroyingPage", "savingPage"),
  hasParent: notEmpty("parent"),

  updateProps(props = {}) {
    const pages = props.pages || this.pages;
    this.set("pages", pages);
    this.updatePages(pages);

    let page;
    if (props.page) {
      page = LandingPage.create(props.page);
    }
    this.set("page", page);
  },

  showErrorMessage(error) {
    this.set("resultMessage", {
      style: "error",
      icon: "xmark",
      text: extractError(error),
    });
    setTimeout(() => this.set("resultMessage", null), 5000);
  },

  @discourseComputed("page.parent_id")
  parent(parentId) {
    const parent = this.pages.findBy("id", parentId);
    return parent ? parent : null;
  },

  @discourseComputed("page.path", "parent")
  pagePath(path, parent) {
    return parent ? parent.path : path;
  },

  @discourseComputed("pagePath")
  pageUrl(pagePath) {
    let url = baseUrl;
    if (pagePath) {
      url += `/${dasherize(pagePath)}`;
    } else {
      url += `/${I18n.t("admin.landing_pages.page.path.placeholder")}`;
    }
    if (this.hasParent) {
      url += `/1`;
    }
    return url;
  },

  @action
  onChangePath(path) {
    if (!this.page.parent_id) {
      this.set("page.path", path);
    }
  },

  @action
  onChangeParent(pageId) {
    this.set("page.parent_id", pageId);
  },

  @action
  createPage() {
    this.updateProps({ page: {} });
  },

  @action
  changePage(pageId) {
    if (pageId) {
      LandingPage.find(pageId).then((result) => this.updateProps(result));
    } else {
      this.updateProps();
    }
  },

  @action
  savePage() {
    this.set("savingPage", true);

    this.page
      .save()
      .then((result) => {
        if (result) {
          this.updateProps(result);
        }
      })
      .catch((error) => this.showErrorMessage(error))
      .finally(() => this.set("savingPage", false));
  },

  @action
  destroyPage() {
    this.set("destroyingPage", true);

    this.page
      .destroy()
      .then((result) => {
        if (result.success) {
          this.updateProps(result);
        }
      })
      .catch((error) => this.showErrorMessage(error))
      .finally(() => this.set("destroyingPage", false));
  },

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
  },
});
