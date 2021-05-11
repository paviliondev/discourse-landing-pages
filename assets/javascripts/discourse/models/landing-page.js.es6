import EmberObject from "@ember/object";
import { ajax } from 'discourse/lib/ajax';
import { url } from "discourse/lib/computed";
import { popupAjaxError } from "discourse/lib/ajax-error";

const basePath = '/landing/page'

const LandingPage = EmberObject.extend({
  exportUrl: url("id", `${basePath}/%@/export`),
  
  savePage() {
    const creating = this.creating;
    let path = basePath;
        
    if (!creating) {
      path += `/${this.id}`;
    }
    
    let page =  {
      name: this.name,
      path: this.path,
      parent_id: this.parent_id,
      category_id: this.category_id,
      theme_id: this.theme_id,
      group_ids: this.group_ids,
      body: this.body,
      menu: this.menu
    }
    
    return ajax(path, {
      type: creating ? "POST" : "PUT",
      data: {
        page
      }
    });
  },
  
  destroyPage() {
    return ajax(`${basePath}/${this.id}`, {
      type: "DELETE"
    }).catch(popupAjaxError);
  }
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
    return ajax(`${basePath}/import`, {
      type: "POST",
      processData: false,
      contentType: false,
      data
    });
  }
});

export default LandingPage;