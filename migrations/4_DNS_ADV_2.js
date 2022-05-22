const dnsadv2 = artifacts.require("DNS_ADV_2");

module.exports = function (deployer) {
  deployer.deploy(dnsadv2);
};
