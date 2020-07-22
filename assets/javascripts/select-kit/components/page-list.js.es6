import ComboBoxComponent from "select-kit/components/combo-box";

export default ComboBoxComponent.extend({
  modifyComponentForRow(collection, item) {
    return "page-list-item";
  }
});