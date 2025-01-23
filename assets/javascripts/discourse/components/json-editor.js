import AceEditor from "discourse/components/ace-editor";

export default class JsonEditor extends AceEditor {
  mode = "json";
  htmlPlaceholder = true;

  _overridePlaceholder(loadedAce) {
    const pluginAcePath = "/plugins/discourse-landing-pages/javascripts/ace";
    loadedAce.config.set("modePath", pluginAcePath);
    loadedAce.config.set("workerPath", pluginAcePath);
    super._overridePlaceholder(...arguments);
  }

  didRender() {
    super.didRender(...arguments);
    if (this._editor) {
      this._editor.setOptions({
        useWorker: true,
        wrap: true,
      });
    }
  }
}
