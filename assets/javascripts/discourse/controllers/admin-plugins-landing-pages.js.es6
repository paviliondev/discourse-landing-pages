import LandingPage from '../models/landing-page';
import Controller from "@ember/controller";
import discourseComputed from "discourse-common/utils/decorators";
import { not, or, gt, notEmpty } from "@ember/object/computed";
import { extractError } from "discourse/lib/ajax-error";
import showModal from "discourse/lib/show-modal";
import { ajax } from 'discourse/lib/ajax';

export default Controller.extend({
  remoteDisconnected: not('remote.connected'),
  pullDisabled: or('pullingFromRemote', 'remoteDisconnected'),
  fetchingCommits: false,
  commitsBehind: null,
  hasCommitsBehind: gt('commitsBehind', 0),
  hasMessage: notEmpty('message'),
  
  @discourseComputed('staticMessage', 'resultMessage', 'page')
  message(staticMessage, resultMessage, page) {
    let text = '';
    let icon = 'info-circle';
    let status = '';
       
    if (resultMessage) {
      text = resultMessage.text;
      status = resultMessage.type;
      setTimeout(() => {
        this.set("resultMessage", null);
      }, 7000);
    } else if (staticMessage) {
      text = staticMessage;
    }
    
    if (text) {
      if (resultMessage) {
        if (status == 'error') {
          icon = 'exclamation-triangle';
        } else if (status == 'success') {
          icon = 'check';
        }
      } else if (page) {
        if (page.remote) {
          icon = 'book';
        } else {
          icon = 'desktop';
        }
      }
      
      return {
        text,
        icon,
        status
      };
    } else {
      return null;
    }
  },
  
  @discourseComputed(
    'pagesNotFetched',
    'hasCommitsBehind',
    'fetchingCommits',
    'page',
    'remote'
  )
  staticMessage(
    pagesNotFetched,
    hasCommitsBehind,
    fetchingCommits,
    page,
    remote
  ) {
    let key;
    
    if (page) {
      if (page.remote) {
        key = 'page.remote.description';
      } else {
        key = 'page.local.description';
      }
    } else if (remote) {
      if (pagesNotFetched) {
        key = 'remote.repository.not_fetched';
      } else if (fetchingCommits) {
        key = 'remote.repository.checking_status';
      } else if (hasCommitsBehind) {
        key = 'remote.repository.out_of_date';
      } else {
        key = 'remote.repository.up_to_date';
      }
    }
    
    if (key) {
      return I18n.t(`admin.landing_pages.${key}`); 
    } else {
      return null;
    }
  },
  
  actions: {
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
        model: {
          remote: this.remote,
          buffered: JSON.parse(JSON.stringify(this.remote))
        }
      });
      controller.set('afterUpdate', (result) => {
        this.setProperties({
          remote: result.remote,
          pagesNotFetched: true
        });
      });
    },
    
    pullFromRemote() {
      this.set("pullingFromRemote", true);
      
      ajax("/landing/remote/pages").then(result => {
        this.setProperties({
          pages: result.pages,
          page: null
        });
        
        let messages = [];
        if (result.report.errors.length) {
          this.set("resultMessage", {
            type: "error",
            text: result.report.errors.join(", ")
          });
        }
        if (result.report.imported.length) {
          this.set("resultMessage", {
            type: "success",
            text: I18n.t("admin.landing_pages.remote.repository.pulled_x", {
              count: result.report.imported.length
            })
          });
        }
      })
      .catch(error => {
        this.set("resultMessage", {
          type: "error",
          text: extractError(error)
        });
      })
      .finally(() => {
        this.set("pullingFromRemote", false)
      });
    },
    
    commitsBehind() {
      this.set("fetchingCommits", true);
      
      ajax("/landing/remote/commits-behind").then(result => {
        if (result.commits_behind) {
          this.set("commitsBehind", result.commits_behind)
        }
      }).finally(() => {
        this.set("fetchingCommits", false);
      });
    }
  }
});