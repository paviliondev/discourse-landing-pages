import SelectKitRowComponent from "select-kit/components/select-kit/select-kit-row";
import discourseComputed from "discourse-common/utils/decorators";

export default SelectKitRowComponent.extend({
  layoutName: "select-kit/templates/components/page-list-item",
  
  @discourseComputed('item.remote')
  pageIcon(remote) {
    if (this.rowValue === this.getValue(this.selectKit.noneItem)) return null;
    return remote ? "code-branch" : "desktop";
  }
});