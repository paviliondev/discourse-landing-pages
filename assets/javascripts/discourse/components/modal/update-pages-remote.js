import Component from "@ember/component";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import { bufferedProperty } from "discourse/mixins/buffered-content";
import { and, or } from "@ember/object/computed";
import { action } from "@ember/object";

export default Component.extend(bufferedProperty("model.remote"), {
  keyGenUrl: "/admin/themes/generate_key_pair",
  remoteUrl: "/landing/remote",
  httpsPlaceholder: "https://github.com/org/repo",
  sshPlaceholder: "git@github.com:org/repo.git",
  showPublicKey: and("buffered.private", "buffered.public_key"),
  testing: false,
  updating: false,
  resetting: false,
  loading: or("testing", "updating", "resetting"),

  @discourseComputed("tested", "loading")
  updateDisabled(tested, loading) {
    return tested !== "success" || loading;
  },

  @discourseComputed("buffered.connected", "loading")
  resetDisabled(connected, loading) {
    return !connected || loading;
  },

  @discourseComputed("buffered.url", "loading")
  testDisabled(url, loading) {
    return !url || loading;
  },

  @discourseComputed("buffered.private")
  urlPlaceholder(isPrivate) {
    return isPrivate ? this.sshPlaceholder : this.httpsPlaceholder;
  },

  @discourseComputed("tested")
  testIcon(tested) {
    return tested === "success" ? "check" : tested === "error" ? "xmark" : null;
  },

  @observes("buffered.hasChanges")
  remoteChanged() {
    this.set("tested", null);
  },

  @observes("buffered.private")
  privateWasChecked() {
    if (
      this.buffered.get("private") &&
      !this.buffered.get("public_key") &&
      !this._keyLoading
    ) {
      this.set("_keyLoading", true);

      ajax(this.keyGenUrl, { type: "POST" })
        .then((result) => {
          this.buffered.setProperties({
            private_key: result.private_key,
            public_key: result.public_key,
          });
        })
        .catch(popupAjaxError)
        .finally(() => this.set("_keyLoading", false));
    }
  },

  buildData() {
    this.commitBuffer();
    const remote = this.model.remote;
    return {
      remote: {
        url: remote.url,
        branch: remote.branch,
        ...(remote.private && { private_key: remote.private_key }),
        ...(remote.private && { public_key: remote.public_key }),
      },
    };
  },

  @action
  test() {
    this.set("testing", true);

    ajax(this.remoteUrl + "/test", {
      type: "POST",
      data: this.buildData(),
    })
      .then((result) => {
        this.set("tested", result.success ? "success" : "error");
      })
      .catch(popupAjaxError)
      .finally(() => this.set("testing", false));
  },

  @action
  update() {
    this.set("updating", true);

    ajax(this.remoteUrl, {
      type: "PUT",
      data: this.buildData(),
    })
      .then((result) => {
        this.closeModal(result);
        this.set("model.remote", {});
      })
      .catch(popupAjaxError)
      .finally(() => this.set("updating", false));
  },

  @action
  reset() {
    this.set("resetting", true);

    ajax(this.remoteUrl, {
      type: "DELETE",
    })
      .then(() => {
        this.closeModal({ remote: {} });
        this.set("model.remote", {});
      })
      .catch(popupAjaxError)
      .finally(() => this.set("resetting", false));
  },
});
