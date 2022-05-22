const dnsadv1 = artifacts.require("DNS_ADV_1");

module.exports = function (deployer) {
  deployer.deploy(dnsadv1);
};
