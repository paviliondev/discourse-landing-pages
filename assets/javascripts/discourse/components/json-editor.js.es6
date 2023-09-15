import AceEditor from "admin/components/ace-editor";

export default class JsonEditor extends AceEditor {
  mode = "json";
  htmlPlaceholder = true;

  _overridePlaceholder(loadedAce) {
    const pluginAcePath = "/plugins/discourse-landing-pages/javascripts/ace";
    loadedAce.config.set("modePath", pluginAcePath);
    loadedAce.config.set("workerPath", pluginAcePath);
    loadedAce.config.set("wrap", true);
    super._overridePlaceholder(...arguments);
  }
}
