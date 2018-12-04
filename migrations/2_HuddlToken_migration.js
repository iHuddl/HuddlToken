var HuddlToken = artifacts.require("HuddlToken");

module.exports = function(deployer) {
  deployer.deploy(HuddlToken, "Huddl", "HUDDL", 18, 100000000);
};