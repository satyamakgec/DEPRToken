pragma solidity 0.6.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

contract DEPRToken is Ownable, ERC20Burnable {

    using Address for address;

    /// Constant that holds token distribution.
    uint256 constant public MULTIPLIER = 10 ** 18;
    uint256 constant public UNISWAP_ALLOCATION = 24000 * MULTIPLIER;
    uint256 constant public PRESALE_ALLOCATION = 26000 * MULTIPLIER;

    /// Private variable to switch off the minting.
    bool private _mintingClosed;
    /// Address of the sale contract address.
    address public preSaleContractAddress;

    /// @dev Contructor to set the token name & symbol.
    ///
    /// @param _tokenName Name of the token.
    /// @param _tokenSymbol Symbol of the token.
    constructor(string memory _tokenName, string memory _tokenSymbol) ERC20(_tokenName, _tokenSymbol) public {
        // Set initial variables
        _mintingClosed = false;
    }

    /// @dev Used to mint initial number of tokens. Called only by the owner of the contract.
    /// This is a one time operation performed by the token issuer.
    ///
    /// @param _saleContractAddress Address of the pre sale contract.
    function initialMint(address _saleContractAddress) public onlyOwner {
        require(!_mintingClosed, "DEPRToken: Intital minting closed");
        require(_saleContractAddress.isContract(), "DEPRToken: Not a valid contract address");
        // Close the minting.
        _mintingClosed = true;
        // Mint Presale tokens to the sale contract address.
        _mint(_saleContractAddress, PRESALE_ALLOCATION);

        // Mint tokens for uniswap allocation.
        _mint(msg.sender, UNISWAP_ALLOCATION);
    }

}