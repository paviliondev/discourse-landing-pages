import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { or, notEmpty, not } from "@ember/object/computed";
import { dasherize } from "@ember/string";
import LandingPage from '../models/landing-page';
import { extractError } from "discourse/lib/ajax-error";

const loation = window.location;
const port = (location.port ? ':' + location.port : '');
const baseUrl = location.protocol + "//" + location.hostname + port;

export default Component.extend({
  classNames: 'page-admin',
  updatingPage: or('destroyingPage', 'savingPage'),
  hasParent: notEmpty('page.parent_id'),
  noParent: not('hasParent'),
  hasPath: or('page.path', 'page.parent_id'),
  
  @discourseComputed('page.parent_id')
  parent(parentId) {
    const parent = this.pages.findBy('id', parentId);
    return parent ? parent : null;
  },
  
  @discourseComputed('page.path', 'parent')
  pagePath(path, parent) {
    return parent ? parent.path : path;
  },
  
  @discourseComputed('pagePath')
  pageUrl(pagePath) {
    let url = baseUrl;
    if (pagePath) {
      url += `/${dasherize(pagePath)}`;
    } else {
      url += `/${I18n.t('admin.landing_pages.page.path.placeholder')}`;
    }
    if (this.hasParent) {
      url += `/${I18n.t('admin.landing_pages.page.parent.param_placeholder')}`;
    }
    return url;
  },
  
  actions: {
    onChangePath(path) {
      if (!this.page.parent_id) {
        this.set('page.path', path);
      }
    },
    
    onChangeParent(pageId) {
      this.set("page.parent_id", pageId);
    },
    
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