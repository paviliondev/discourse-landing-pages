import { later } from "@ember/runloop";
import LandingPage from '../models/landing-page';
import Controller from "@ember/controller";
import { dasherize } from "@ember/string";
import discourseComputed from "discourse-common/utils/decorators";
import { equal } from "@ember/object/computed";
import { extractError } from "discourse/lib/ajax-error";

export default Controller.extend({
  creating: equal('page.id', 'create'),
  
  @discourseComputed('page.path')
  pageUrl(pagePath) {
    const loation = window.location;
    const port = (location.port ? ':' + location.port : '');
    let url =  location.protocol + "//" + location.hostname + port;
    if (pagePath) {
      url += `/${dasherize(pagePath)}`;
    }
    return url;
  },
  
  actions: {
    savePage() {
      this.setProperties({
        loading: true,
        error: null
      });
      
      const page = this.get('page');
      let opts = {};
      let self = this;
      
      if (this.creating) {
        opts.create = true;
      }
            
      page.savePage(opts).then(result => {
        if (result.success) {
          this.setProperties({
            page:  LandingPage.create(result.page),
            currentPage: JSON.parse(JSON.stringify(result.page)),
            pages: result.pages
          });
        } else {
          this.set('page', self.currentPage);
        }
      }).catch(error => {
        this.setProperties({
          error: extractError(error),
          page: self.currentPage
        });
        later(() => this.set('error', null), 10000);
      }).finally(() => {
        this.set('loading', false);
      });
    },
    
    destroyPage() {
      this.page.destroyPage().then(() => {
        this.send('afterDestroy');
      });
    },
    
    changePage(pageId) {
      LandingPage.find(pageId).then(data => {
        if (data) {
          const page = LandingPage.create(data);
          this.setProperties({
            page,
            currentPage: JSON.parse(JSON.stringify(page))
          });
        }
      });
    },
    
    createPage() {
      this.set('page', LandingPage.create({ id: 'create' }));
    }
  }
});