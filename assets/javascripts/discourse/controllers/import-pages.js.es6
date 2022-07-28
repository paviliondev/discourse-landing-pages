import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import LandingPage from "../models/landing-page";
import { popupAjaxError } from "discourse/lib/ajax-error";
import bootbox from "bootbox";

export default Controller.extend(ModalFunctionality, {
  actions: {
    uploadFile() {
      this.set("pageFile", $("#file-input")[0].files[0]);
    },

    importPage() {
      let data = new FormData();
      data.append("page", this.pageFile);

      this.set("loading", true);
      LandingPage.import(data)
        .then((result) => {
          this.afterImport(result);
          this.send("closeModal");
        })
        .catch(function (e) {
          if (typeof e === "string") {
            bootbox.alert(e);
          } else {
            popupAjaxError(e);
          }
        })
        .finally(() => this.set("loading", false));
    },
  },
});
