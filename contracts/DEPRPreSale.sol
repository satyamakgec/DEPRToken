pragma solidity 0.6.2;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "./DEPRToken.sol";

contract DEPRPreSale is ReentrancyGuard, Ownable {

    using Address for address payable;
    using SafeMath for uint256;

    DEPRToken public token;

    /// Sale phases timings.
    ///
    /// Early Phase starts once open() function is called.
    /// while token rate during this phase is ~ 0.0033 i.e 1 ETH = 300 tokens.
    ///
    /// Late Phase starts once early phase cap reaches.
    /// while token rate during this phase is ~ 0.0037 i.e 1 ETH = 270 tokens.
    ///
    /// Once late phase cap is achieved sale become closed.

    uint256 constant public EARLY_PHASE_CAP = 50 ether;
    uint256 constant public LATE_PHASE_CAP = 100 ether;

    uint256 constant public EARLY_PHASE_MINIMUM_INVESTMENT_CAP = 2 ether / 10;
    uint256 constant public LATE_PHASE_MINIMUM_INVESTMENT_CAP = 1 ether / 10;
    
    /// Multiplier to provide precision.
    uint256 constant public MULTIPLIER = 10 ** 18;

    /// Rates for different phases of the sale.
    uint256 constant public EALRY_PHASE_RATE = 300 * MULTIPLIER;  /// i.e 300 tokens = 1 ETH.
    uint256 constant public LATE_PHASE_RATE = 270 * MULTIPLIER;  /// i.e 270 tokens = 1 ETH.

    /// No. of total ETH raised.
    uint256 public fundCollected;

    /// Address receives the funds collected from the sale.
    address public fundsReceiver;
    /// Boolean variable to provide the status of sale.
    bool public isOpen;

    /// Event emitted when tokens are bought by the investor.
    event TokensBought(address indexed _beneficiary, uint256 _amount);

    /// @dev fallback function to receives ETH.
    receive() external payable {
        // calls `buyTokens()`
        buyTokens();
    }


    /// @dev Constructor to set initial values for the contract.
    /// 
    /// @param _tokenAddress Address of the token that gets distributed.
    /// @param _fundsReceiver Address that receives the funds collected from the sale.
    constructor(address _tokenAddress, address _fundsReceiver) public {
        // 0x0 is not allowed. It is only a sanity check.
        _checkForZeroAddress(_tokenAddress);
        _checkForZeroAddress(_fundsReceiver);
        // Assign variables. 
        token = DEPRToken(_tokenAddress);
        fundsReceiver = _fundsReceiver;

        // Set sale status to false.
        isOpen = false;
    }

    /// @dev Used to open the sale contract.
    function open() public onlyOwner {  
        require(!isOpen, "DEPRPreSale: Sale is already open");
        require(token.balanceOf(address(this)) > uint256(0), "DEPRPreSale: Balance is insufficient");
        isOpen = true;
    }

    /// @dev Transfer tokens to the owner address.
    function reclaimTokens(uint256 _amount) public onlyOwner {
        require(token.transfer(_msgSender(), _amount), "DEPRPreSale: Transfer failed");
    }


    /// @dev Used to buy tokens using ETH. It is only allowed to call when sale is running.
    function buyTokens() public payable nonReentrant {
        // Check whether sale is in running or not.
        _hasSaleOpen();

        // Check for the 0 value.
        require(msg.value > 0, "DEPRPreSale: Zero investments aren't allowed");

        // Calculate the amount of tokens to sale.
        uint256 tokensToSale = getROI(msg.value);
    
        // Sends funds to funds collector wallet.
        address(uint160(fundsReceiver)).sendValue(msg.value);
        // Tokens get transfered from this contract to the buyer.
        require(token.transfer(msg.sender, tokensToSale), "DEPRPreSale: Transfer failed");
        // Emit event.
        emit TokensBought(msg.sender, tokensToSale);
    }


    /// @dev Public getter to fetch the no. of tokens .
    function getROI(uint256 _amount) internal returns(uint256 _roi) {
        if (fundCollected < EARLY_PHASE_CAP) {
            require(_amount >= EARLY_PHASE_MINIMUM_INVESTMENT_CAP, "DEPRPreSale: Less than minimum allowed investment amount in early phase");
            uint256 newFundsAmount = fundCollected.add(_amount);
            if (newFundsAmount > EARLY_PHASE_CAP) {
                _roi = (_amount.sub(newFundsAmount - EARLY_PHASE_CAP) * EALRY_PHASE_RATE).div(MULTIPLIER);
                fundCollected = fundCollected.add(_amount.sub(newFundsAmount - EARLY_PHASE_CAP));
                _roi = _roi + _getLatePhaseROI(newFundsAmount - EARLY_PHASE_CAP);
            } else {
                _roi = _amount * EALRY_PHASE_RATE / MULTIPLIER;
                fundCollected = fundCollected.add(_amount);
            }
        } else {
            require(_amount >= LATE_PHASE_MINIMUM_INVESTMENT_CAP, "DEPRPreSale: Less than minimum allowed investment amount in late phase");
            _roi = _getLatePhaseROI(_amount);
        }
    }

    function _getLatePhaseROI(uint256 _amount) internal returns(uint256 _roi) {
        uint256 newFundsAmount = fundCollected.add(_amount);
        if (newFundsAmount > (EARLY_PHASE_CAP + LATE_PHASE_CAP)) {
            // This extra amount needs to refund
            uint256 extraAmount = newFundsAmount - (EARLY_PHASE_CAP + LATE_PHASE_CAP);
            _amount = _amount - extraAmount;
            // Initiate refund of extra ETHs
            address(uint160(_msgSender())).sendValue(extraAmount);
        }
        _roi = _amount * LATE_PHASE_RATE / MULTIPLIER;
        fundCollected = fundCollected.add(_amount);
    }

    function _hasSaleOpen() internal view {
        require(isOpen, "DEPRPreSale: Sale has yet to be started");
        require(fundCollected < EARLY_PHASE_CAP + LATE_PHASE_CAP, "DEPRPreSale: Cap is reached, Sale closed");
    }

    function _checkForZeroAddress(address _target) internal pure {
        require(_target != address(0), "DEPRPreSale: Invalid address");
    }

}