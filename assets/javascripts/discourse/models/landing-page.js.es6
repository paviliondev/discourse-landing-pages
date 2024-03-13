import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { url } from "discourse/lib/computed";
import { popupAjaxError } from "discourse/lib/ajax-error";

const basePath = "/landing/page";

const LandingPage = EmberObject.extend({
  exportUrl: url("id", `${basePath}/%@/export`),

  save() {
    const path = this.id ? `${basePath}/${this.id}` : basePath;
    const method = this.id ? "PUT" : "POST";

    let page = {
      name: this.name,
      path: this.path,
      parent_id: this.parent_id,
      category_id: this.category_id,
      theme_id: this.theme_id,
      group_ids: this.group_ids,
      body: this.body,
      menu: this.menu,
    };

    return ajax(path, {
      type: method,
      contentType: "application/json; charset=UTF-8",
      data: JSON.stringify(page),
    });
  },

  destroy() {
    return ajax(`${basePath}/${this.id}`, {
      type: "DELETE",
    }).catch(popupAjaxError);
  },

  export() {
    return ajax(this.exportUrl, {
      type: "GET",
      dataType: "binary",
      xhrFields: {
        responseType: "blob",
      },
    });
  },
});

LandingPage.reopenClass({
  all() {
    return ajax(basePath).catch(popupAjaxError);
  },

  find(pageId) {
    return ajax(`${basePath}/${pageId}`).catch(popupAjaxError);
  },

  create(props = {}) {
    const page = this._super.apply(this);
    page.setProperties(props);
    return page;
  },

  import(data) {
    return ajax(`${basePath}/upload`, {
      type: "POST",
      processData: false,
      contentType: false,
      data,
    });
  },
});

export default LandingPage;
