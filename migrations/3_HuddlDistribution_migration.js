var HuddlDistribution = artifacts.require("HuddlDistribution");
var HuddlToken = artifacts.require("HuddlToken");

module.exports = async(deployer) => {
  await deployer.deploy(HuddlDistribution, HuddlToken.address, "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225");
   var token = await HuddlToken.deployed();
   
   await token.addMinter(HuddlDistribution.address);
   await token.renounceMinter();
   await token.transfer(HuddlDistribution.address, 100000000000000000000000000);
};