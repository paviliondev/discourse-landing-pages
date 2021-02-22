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
          self.setProperties({
            page:  LandingPage.create(result.page),
            currentPage: JSON.parse(JSON.stringify(result.page))
          });
          self.updatePages(result.pages);
        } else {
          self.set('page', self.currentPage);
        }
      }).catch(error => {
        self.set("resultMessage", {
          type: 'error',
          icon: 'times',
          text: extractError(error)
        });
        
        setTimeout(() => {
          self.set('resultMessage', null);
        }, 5000);
        
        if (self.currentPage) {
          self.set("page", self.currentPage);
        }  
      }).finally(() => {
        self.set('savingPage', false);
      });
    },
    
    destroyPage() {
      this.set("destroyingPage", true);
      
      this.page.destroyPage().then(result => {
        if (result.success) {
          this.set('page', null);
        }
      }).finally(() => {
        this.set('destroyingPage', false);
      });
    },
    
    exportPage() {
      this.page.exportPage().catch(error => {
        this.set("resultMessage", {
          type: 'error',
          icon: 'icon',
          text: extractError(error)
        });
        
        setTimeout(() => {
          self.set('resultMessage', null);
        }, 5000);
      })
    }
  }
});