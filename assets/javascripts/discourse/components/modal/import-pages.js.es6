import Component from "@ember/component";
import LandingPage from "../../models/landing-page";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { action } from "@ember/object";
import { service } from "@ember/service";
import bootbox from "bootbox";

export default Component.extend({
  dialog: service(),

  @action
  uploadFile() {
    this.set("pageFile", $("#file-input")[0].files[0]);
  },

  @action
  importPage() {
    let data = new FormData();
    data.append("page", this.pageFile);

    this.set("loading", true);
    LandingPage.import(data)
      .then((result) => {
        this.closeModal(result);
      })
      .catch(function (e) {
        if (typeof e === "string") {
          this.dialog.alert(e);
        } else {
          popupAjaxError(e);
        }
      })
      .finally(() => this.set("loading", false));
  },
});
