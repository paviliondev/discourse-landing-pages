import EmberObject from "@ember/object";
import { ajax } from 'discourse/lib/ajax';

const basePath = '/landing/page'

const LandingPage = EmberObject.extend({
  savePage(opts={}) {
    let path = basePath;
        
    if (!opts.create) {
      path += `/${this.id}`;
    }
    
    let page =  {
      name: this.name,
      path: this.path,
      theme_id: this.theme_id,
      body: this.body
    }
    
    return ajax(path, {
      type: opts.create ? "POST" : "PUT",
      data: {
        page
      }
    });
  },
  
  destroyPage() {
    return ajax(`${basePath}/${this.id}`, {
      type: "DELETE"
    });
  }
});

LandingPage.reopenClass({
  all() {
    return ajax(basePath);
  },
  
  find(pageId) {
    return ajax(`${basePath}/${pageId}`);
  },

  create(props = {}) {
    const page = this._super.apply(this);
    page.setProperties(props);
    return page;
  }
});

export default LandingPage;