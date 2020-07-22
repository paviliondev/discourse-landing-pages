import Controller from "@ember/controller";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import { and } from "@ember/object/computed";

export default Controller.extend({
  keyGenUrl: "/admin/themes/generate_key_pair",
  remoteUrl: "/landing/remote",
  urlPlaceholder: "https://github.com/paviliondev/pages",
  showPublicKey: and("model.private", "model.public_key"),
  
  @discourseComputed("loading", "model.url")
  installDisabled(isLoading, url) {
    return isLoading || !url;
  },
  
  @observes("model.private")
  privateWasChecked() {
    const model = this.model;
    if (!model) return;
    
    model.private
      ? this.set("urlPlaceholder", "git@github.com:paviliondev/pages.git")
      : this.set("urlPlaceholder", "https://github.com/paviliondev/pages");

    if (model.private && !model.public_key && !this._keyLoading) {
      this._keyLoading = true;
      ajax(this.keyGenUrl, { type: "POST" })
        .then(pair => {
          model.setProperties({
            private_key: pair.private_key,
            public_key: pair.public_key
          });
        })
        .catch(popupAjaxError)
        .finally(() => {
          this._keyLoading = false;
        });
    }
  },
  
  actions: {
    update() {
      const model = this.model;
      
      let options = {
        type: "PUT",
        data: {
          remote: {
            url: model.url,
            branch: model.branch,
          }
        }
      };

      if (model.private) {
        options.data.remote.private_key = model.private_key;
        options.data.remote.public_key = model.public_key;
      }
      
      this.set("loading", true);
      ajax(this.remoteUrl, options)
        .then(result => {
          this.afterUpdate(result);
          this.send("closeModal");
          this.set("model", null);
        })
        .catch(popupAjaxError)
        .finally(() => this.set("loading", false));
    }
  }
})