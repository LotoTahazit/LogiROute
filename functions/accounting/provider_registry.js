const greeninvoice = require("./adapters/greeninvoice");
const icount = require("./adapters/icount");
const fileExport = require("./adapters/file_export");

const ADAPTERS = {
  none: null,
  export: fileExport,
  greeninvoice,
  icount,
};

function getAccountingAdapter(provider) {
  return ADAPTERS[provider] || null;
}

module.exports = { getAccountingAdapter, ADAPTERS };
