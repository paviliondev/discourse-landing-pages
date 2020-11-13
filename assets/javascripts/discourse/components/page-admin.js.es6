import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { or } from "@ember/object/computed";
import { dasherize } from "@ember/string";
import LandingPage from '../models/landing-page';
import { extractError } from "discourse/lib/ajax-error";

export default Component.extend({
  classNames: 'page-admin',
  updatingPage: or('destroyingPage', 'savingPage'),
  
  @discourseComputed('page.path')
  pageUrl(pagePath) {
    const loation = window.location;
    const port = (location.port ? ':' + location.port : '');
    let url = location.protocol + "//" + location.hostname + port;
    if (pagePath) {
      url += `/${dasherize(pagePath)}`;
    }
    return url;
  },
  
  actions: {
    savePage() {
      this.set('savingPage', true);

      const page = this.get('page');
      let self = this;
            
      page.savePage().then(result => {
        if (result.page) {
          this.setProperties({
            page:  LandingPage.create(result.page),
            currentPage: JSON.parse(JSON.stringify(result.page)),
            pages: result.pages
          });
        } else {
          this.set('page', self.currentPage);
        }
      }).catch(error => {
        this.handleResult()
        this.set("resultMessage", {
          type: 'error',
          text: extractError(error)
        });
        this.set("page", self.currentPage);
      }).finally(() => {
        this.set('savingPage', false);
      });
    },
    
    destroyPage() {
      this.set("destroyingPage", true);
      
      this.page.destroyPage().then(result => {
        if (result.success) {
          this.setProperties({
            page: null,
            pages: result.pages
          })
        }
      }).finally(() => {
        this.set('destroyingPage', false);
      });
    },
    
    exportPage() {
      this.page.exportPage().catch(error => {
        this.set("resultMessage", {
          type: 'error',
          text: extractError(error)
        });
      })
    }
  }
});