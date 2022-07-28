import ComboBoxComponent from "select-kit/components/combo-box";

export default ComboBoxComponent.extend({
  modifyComponentForRow() {
    return "page-list-item";
  },
});
