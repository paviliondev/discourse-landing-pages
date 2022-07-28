import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const basePath = "/landing/global";
const LandingPageGlobal = EmberObject.extend();

LandingPageGlobal.reopenClass({
  save(data) {
    return ajax(`${basePath}`, {
      type: "PUT",
      data,
    }).catch(popupAjaxError);
  },

  destroy() {
    return ajax(`${basePath}`, {
      type: "DELETE",
    }).catch(popupAjaxError);
  },
});

export default LandingPageGlobal;
