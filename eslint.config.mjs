import DiscourseRecommended from "@discourse/lint-configs/eslint";

export default [
  ...DiscourseRecommended,
  {
    rules: {
      "simple-import-sort/imports": "off",
      "qunit/no-loose-assertions": "off",
      "qunit/no-ok-equality": "off",
    },
  },
];
