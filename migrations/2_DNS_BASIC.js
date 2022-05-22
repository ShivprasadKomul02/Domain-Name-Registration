const dnsbasic = artifacts.require("DNS_BASIC");

module.exports = function (deployer) {
  deployer.deploy(dnsbasic);
};
