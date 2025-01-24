import ImportPages from "../components/modal/import-pages";
import UpdatePagesRemote from "../components/modal/update-pages-remote";
import Controller from "@ember/controller";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import { gt, not, notEmpty, or } from "@ember/object/computed";
import { extractError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import I18n from "I18n";

const statusIcons = {
  error: "exclamation-triangle",
  success: "check",
};

export default Controller.extend({
  modal: service(),

  remoteDisconnected: not("remote.connected"),
  pullDisabled: or("pullingFromRemote", "remoteDisconnected"),
  fetchingCommits: false,
  commitsBehind: null,
  hasCommitsBehind: gt("commitsBehind", 0),
  hasMessages: notEmpty("messages.items"),
  showCommitsBehind: false,
  showPages: true,

  @discourseComputed("staticMessage", "resultMessages")
  messages(staticMessage, resultMessages) {
    if (resultMessages) {
      setTimeout(() => {
        this.set("resultMessages", null);
      }, 15000);

      return {
        status: resultMessages.type,
        items: resultMessages.messages.map((message) => {
          return {
            icon: statusIcons[resultMessages.type],
            text: message,
          };
        }),
      };
    } else if (staticMessage) {
      return {
        status: "static",
        items: [
          {
            icon: staticMessage.icon,
            text: staticMessage.text,
          },
        ],
      };
    } else {
      return null;
    }
  },

  @discourseComputed(
    "pagesNotFetched",
    "hasCommitsBehind",
    "fetchingCommits",
    "page",
    "remote",
    "showGlobal"
  )
  staticMessage(
    pagesNotFetched,
    hasCommitsBehind,
    fetchingCommits,
    page,
    remote,
    showGlobal
  ) {
    let key;
    let icon = "info-circle";

    if (page) {
      if (page.remote) {
        key = "page.remote.description";
        icon = "book";
      } else {
        key = "page.local.description";
        icon = "desktop";
      }
    } else if (showGlobal) {
      key = "global.description";
    } else if (remote && remote.connected) {
      if (pagesNotFetched) {
        key = "remote.repository.not_fetched";
      } else if (fetchingCommits) {
        key = "remote.repository.checking_status";
      } else if (hasCommitsBehind) {
        key = "remote.repository.out_of_date";
      } else {
        key = "remote.repository.up_to_date";
      }
    }

    if (key) {
      return {
        icon,
        text: I18n.t(`admin.landing_pages.${key}`),
      };
    } else {
      return null;
    }
  },

  @discourseComputed("showGlobal")
  documentationUrl(showGlobal) {
    const rootUrl = "https://coop.pavilion.tech";
    return showGlobal ? `${rootUrl}` : `${rootUrl}`;
  },

  actions: {
    importPages() {
      this.modal.show(ImportPages).then((result) => {
        if (result?.page) {
          this.setProperties({
            pages: result.pages,
            resultMessages: {
              type: "success",
              messages: [
                I18n.t("admin.landing_pages.imported.x_pages", { count: 1 }),
              ],
            },
          });
        }
      });
    },

    updateRemote() {
      this.modal
        .show(UpdatePagesRemote, { model: { remote: this.remote } })
        .then((result) => {
          if (result?.remote) {
            this.setProperties({
              remote: result.remote,
              pagesNotFetched: true,
            });
          }
        });
    },

    pullFromRemote() {
      this.set("pullingFromRemote", true);

      ajax("/landing/remote/pages")
        .then((result) => {
          const pages = result.pages;
          const menus = result.menus;
          const global = result.global;
          const report = result.report;

          this.setProperties({
            pages,
            menus,
            global,
          });

          if (report.errors.length) {
            this.set("resultMessages", {
              type: "error",
              messages: result.report.errors,
            });
          } else {
            let imported = report.imported;
            let messages = [];

            ["scripts", "menus", "assets", "pages"].forEach((listType) => {
              if (imported[listType].length) {
                messages.push(
                  I18n.t(`admin.landing_pages.imported.x_${listType}`, {
                    count: imported[listType].length,
                  })
                );
              }
            });

            ["footer", "header"].forEach((boolType) => {
              if (imported[boolType]) {
                messages.push(
                  I18n.t(`admin.landing_pages.imported.${boolType}`)
                );
              }
            });

            this.setProperties({
              resultMessages: { type: "success", messages },
              pagesNotFetched: false,
            });

            this.send("commitsBehind");
          }
        })
        .catch((error) => {
          this.set("resultMessages", {
            type: "error",
            messages: [extractError(error)],
          });
        })
        .finally(() => {
          this.set("pullingFromRemote", false);
        });
    },

    commitsBehind() {
      this.set("fetchingCommits", true);

      ajax("/landing/remote/commits-behind")
        .then((result) => {
          if (!result.failed) {
            this.set("commitsBehind", result.commits_behind);
          }
        })
        .finally(() => {
          this.set("fetchingCommits", false);
        });
    },

    updatePages(pages) {
      this.set("pages", pages);
    },

    toggleShowPages() {
      this.setProperties({
        showPages: true,
        showGlobal: false,
      });
    },

    toggleShowGlobal() {
      this.setProperties({
        showPages: false,
        showGlobal: true,
      });
    },
  },
});
