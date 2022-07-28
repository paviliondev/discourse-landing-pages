import Controller from "@ember/controller";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import { and } from "@ember/object/computed";

export default Controller.extend({
  keyGenUrl: "/admin/themes/generate_key_pair",
  remoteUrl: "/landing/remote",
  urlPlaceholder: "https://github.com/paviliondev/pages",
  showPublicKey: and("model.remote.private", "model.remote.public_key"),
  tested: false,
  remoteChanged: false,
  updating: false,

  @observes(
    "model.remote.url",
    "model.remote.branch",
    "model.remote.private",
    "model.remote.public_key",
    "model.remote.private_key"
  )
  remoteUpdated() {
    const model = this.model;
    if (!model) {
      return;
    }

    const remote = model.remote;
    const buffered = model.buffered;

    let remoteChanged = false;

    if (remote && buffered) {
      remoteChanged = [
        "url",
        "branch",
        "private",
        "public_key",
        "private_key",
      ].some((k) => {
        return buffered[k] !== remote[k];
      });
    }

    this.setProperties({
      remoteChanged,
      buffered: remote,
      tested: this.tested && !remoteChanged,
    });
  },

  @discourseComputed(
    "remoteChanged",
    "updating",
    "tested",
    "testing",
    "connected"
  )
  updateDisabled(remoteChanged, updating, tested, testing, connected) {
    return !remoteChanged || updating || !tested || testing || !connected;
  },

  @discourseComputed("testing", "model.remote.url")
  testDisabled(testing, url) {
    return testing || !url;
  },

  @discourseComputed("tested", "connected")
  testStatus(tested, connected) {
    if (!tested) {
      return null;
    }
    return connected ? "success" : "failed";
  },

  @discourseComputed("connected")
  testIcon(connected) {
    return connected ? "check" : "times";
  },

  @observes("model.remote.private")
  privateWasChecked() {
    const model = this.model;
    if (!model || !model.remote) {
      return;
    }

    const remote = model.remote;

    remote.private
      ? this.set("urlPlaceholder", "git@github.com:paviliondev/pages.git")
      : this.set(
          "urlPlaceholder",
          "https://github.com/paviliondev/pavilion-landing-pages"
        );

    if (remote.private && !remote.public_key && !this._keyLoading) {
      this._keyLoading = true;
      ajax(this.keyGenUrl, { type: "POST" })
        .then((pair) => {
          remote.setProperties({
            private_key: pair.private_key,
            public_key: pair.public_key,
          });
        })
        .catch(popupAjaxError)
        .finally(() => {
          this._keyLoading = false;
        });
    }
  },

  buildData() {
    const remote = this.model.remote;

    let data = {
      remote: {
        url: remote.url,
        branch: remote.branch,
      },
    };

    if (remote.private) {
      data.remote.private_key = remote.private_key;
      data.remote.public_key = remote.public_key;
    }

    return data;
  },

  actions: {
    test() {
      this.set("testing", true);

      ajax(this.remoteUrl + "/test", {
        type: "POST",
        data: this.buildData(),
      })
        .then((result) => {
          this.set("connected", !!result.success);
        })
        .catch(popupAjaxError)
        .finally(() =>
          this.setProperties({
            testing: false,
            tested: true,
          })
        );
    },

    update() {
      this.set("updating", true);

      ajax(this.remoteUrl, {
        type: "PUT",
        data: this.buildData(),
      })
        .then((result) => {
          this.afterUpdate(result);
          this.send("closeModal");
          this.set("model", null);
        })
        .catch(popupAjaxError)
        .finally(() => this.set("updating", false));
    },
  },
});
