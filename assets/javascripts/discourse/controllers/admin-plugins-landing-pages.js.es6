import { later } from "@ember/runloop";
import LandingPage from '../models/landing-page';
import Controller from "@ember/controller";
import { dasherize } from "@ember/string";
import discourseComputed from "discourse-common/utils/decorators";
import { equal, notEmpty } from "@ember/object/computed";
import { extractError } from "discourse/lib/ajax-error";
import showModal from "discourse/lib/show-modal";
import { ajax } from 'discourse/lib/ajax';
import { A } from "@ember/array";

export default Controller.extend({
  messages: A(),
  hasMessages: notEmpty('messages'),
  
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
  
  displayMessage(type, text) {
    let obj = { type, text };
    this.messages.pushObject(obj);
    later(() => this.messages.removeObject(obj), 10000);
  },
  
  actions: {
    savePage() {
      this.setProperties({
        loading: true,
        message: null
      });
      
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
        this.displayMessage("error", extractError(error));
        this.set("page", self.currentPage);
      }).finally(() => {
        this.set('loading', false);
      });
    },
    
    destroyPage() {
      this.page.destroyPage().then(result => {
        if (result.success) {
          this.setProperties({
            page: null,
            pages: result.pages
          })
        }
      }).finally(() => {
        this.set('loading', false);
      });
    },
    
    exportPage() {
      this.page.exportPage().catch(error => {
        this.displayMessage("error", extractError(error));
      })
    },
    
    changePage(pageId) {
      if (pageId) {
        LandingPage.find(pageId).then(result => {
          if (result.page) {
            const page = LandingPage.create(result.page);
            this.setProperties({
              page,
              currentPage: JSON.parse(JSON.stringify(page))
            });
          }
        });
      } else {
        this.setProperties({
          page: null,
          currentPage: null
        });
      };
    },
    
    createPage() {
      this.set('page', LandingPage.create({ creating: true }));
    },
    
    importPages() {
      const controller = showModal('import-pages');
      controller.set('afterImport', (result) => {
        this.setProperties({
          page: LandingPage.create(result.page),
          currentPage: JSON.parse(JSON.stringify(result.page)),
          pages: result.pages
        });
      });
    },
    
    updateRemote() {
      const controller = showModal('update-pages-remote', {
        model: this.remote
      });
      controller.set('afterUpdate', (result) => {
        this.setProperties({
          pages: result.pages
        });
      });
    },
    
    importFromRemote() {
      this.set("importingFromRemote", true);
      
      ajax("/landing/remote/pages").then(result => {
        this.setProperties({
          pages: result.pages,
          page: null
        });
        
        let messages = [];
        if (result.report.errors.length) {
          this.displayMessage("error", result.report.errors.join(", "));
        }
        if (result.report.imported.length) {
          this.displayMessage("info", result.report.imported.join(", "));
        }
      })
      .catch(error => {
        this.displayMessage("error", extractError(error));
      })
      .finally(() => {
        this.set("importingFromRemote", false)
      });
    }
  }
});