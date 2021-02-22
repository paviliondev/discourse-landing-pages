import LandingPage from '../models/landing-page';
import Controller from "@ember/controller";
import discourseComputed from "discourse-common/utils/decorators";
import { not, or, gt, notEmpty } from "@ember/object/computed";
import { extractError } from "discourse/lib/ajax-error";
import showModal from "discourse/lib/show-modal";
import { ajax } from 'discourse/lib/ajax';

const statusIcons = {
  error: 'exclamation-triangle',
  success: 'check'
}

export default Controller.extend({
  remoteDisconnected: not('remote.connected'),
  pullDisabled: or('pullingFromRemote', 'remoteDisconnected'),
  fetchingCommits: false,
  commitsBehind: null,
  hasCommitsBehind: gt('commitsBehind', 0),
  hasMessages: notEmpty('messages.items'),
  
  @discourseComputed('hasCommitsBehind', 'fetchingCommits')
  showCommitsBehind(hasCommitsBehind, fetchingCommits) {
    return hasCommitsBehind && !fetchingCommits;
  },
  
  @discourseComputed('staticMessage', 'resultMessages')
  messages(staticMessage, resultMessages) {
    if (resultMessages) {
      setTimeout(() => {
        this.set("resultMessages", null);
      }, 15000);
      
      return {
        status: resultMessages.type,
        items: resultMessages.messages.map(message => {
          return {
            icon: statusIcons[resultMessages.type],
            text: message
          }
        })
      }
    } else if (staticMessage) {
      return {
        status: 'static',
        items: [{
          icon: staticMessage.icon,
          text: staticMessage.text
        }]
      }
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
    let icon = 'info-circle';
        
    if (page) {
      if (page.remote) {
        key = 'page.remote.description';
        icon = 'book';
      } else {
        key = 'page.local.description';
        icon = 'desktop';
      }
    } else if (remote && remote.connected) {
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
      return {
        icon,
        text: I18n.t(`admin.landing_pages.${key}`)
      }; 
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
        const pages = result.pages;
        const menus = result.menus;
        const report = result.report;
        
        this.setProperties({
          pages,
          menus,
          page: null
        });
                        
        if (report.errors.length) {
          this.set("resultMessages", {
            type: "error",
            messages: result.report.errors
          });
        } else {
          let imported = report.imported;
          let messages = [];
          
          ['scripts', 'menus', 'assets', 'pages'].forEach(listType => {
            if (imported[listType].length) {
              messages.push(
                I18n.t(`admin.landing_pages.imported.x_${listType}`, {
                  count: imported[listType].length
                })
              );
            }
          });
          
          ['footer', 'header'].forEach(boolType => {
            messages.push(
              I18n.t(`admin.landing_pages.imported.${boolType}`)
            );
          });
                    
          this.set("resultMessages", {
            type: "success",
            messages
          });
          
          this.send('commitsBehind');
        }
      })
      .catch(error => {
        this.set("resultMessages", {
          type: "error",
          messages: [ extractError(error) ]
        });
      })
      .finally(() => {
        this.set("pullingFromRemote", false)
      });
    },
    
    commitsBehind() {
      this.set("fetchingCommits", true);
      
      ajax("/landing/remote/commits-behind").then(result => {
        if (!result.failed) {
          this.set("commitsBehind", result.commits_behind)
        }
      }).finally(() => {
        this.set("fetchingCommits", false);
      });
    },
    
    updatePages(pages) {
      this.set('pages', pages);
    }
  }
});