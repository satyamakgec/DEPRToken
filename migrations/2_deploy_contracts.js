const ERC20Token = artifacts.require("DEPRToken");
const PreSale = artifacts.require("DEPRPreSale");

module.exports = function(deployer, network, accounts) {
  let name = "DegenPro Finance";
  let symbol = "DEPR";

  if (network === "development") {
    let fundsReceiver = accounts[0];

    return deployer.deploy(ERC20Token, name, symbol).then(() => {
      return deployer.deploy(PreSale, ERC20Token.address, fundsReceiver);
    });

  } else if (network === "ropsten") {
    let fundsReceiver = "0x062306daAFD2dBA9e80f34B56220f7Df83954313";

    return deployer.deploy(ERC20Token, name, symbol).then(() => {
      return deployer.deploy(PreSale, ERC20Token.address, fundsReceiver);
    });

  } else if (network === "mainnet" || network === "mainnet-fork") {
    let fundsReceiver = "0x903AE1B519395049d7f56779C66FF74047577c1f";

    return deployer.deploy(ERC20Token, name, symbol, {from: accounts[0]}).then(() => {
      return deployer.deploy(PreSale, ERC20Token.address, fundsReceiver, {from: accounts[0]}).then(() => {
        return ERC20Token.initialMint(PreSale.address, {from: accounts[0]}).then(() => {
          return PreSale.open({from: accounts[0]});
        });
      });
    });
    
  }

}
