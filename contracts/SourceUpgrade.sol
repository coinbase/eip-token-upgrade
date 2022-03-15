//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IEIPUPGRADEABLE.sol";

contract SourceUpgrade is  IEIPUPGRADEABLE {
    using SafeERC20  for IERC20;

    uint256 constant RATIO_SCALE = 10**18;
    
    IERC20 private source;
    IERC20 private destination;
    bool private upgradeStatus;
    bool private downgradeStatus;
    uint256 private numeratorRatio;
    uint256 private denominatorRatio;
    uint256 private sourceUpgradedTotal;
    
    mapping(address => uint256) public upgradedBalance;
    
    constructor(address _source, address _destination, bool _upgradeStatus, bool _downgradeStatus, uint256 _numeratorRatio, uint256 _denominatorRatio) {
	require(_source != _destination, "SourceUpgrade: source and destination addresses are the same");
	require(_source != address(0), "SourceUpgrade: source address cannot be zero address");
	require(_destination != address(0), "SourceUpgrade: destination address cannot be zero address");
	require(_numeratorRatio > 0, "SourceUpgrade: numerator of ratio cannot be zero");
	require(_denominatorRatio > 0, "SourceUpgrade: denominator of ratio cannot be zero");
	
	source = IERC20(_source);
	destination = IERC20(_destination);
	upgradeStatus = _upgradeStatus;
	downgradeStatus = _downgradeStatus;
	numeratorRatio = _numeratorRatio;
	denominatorRatio = _denominatorRatio;
    }

    /// @dev A getter to determine the contract that is being upgraded from ("source contract")
    /// @return The address of the source token contract
    function upgradeSource() external view returns(address) {
	return address(source);
    }

    /// @dev A getter to determine the contract that is being upgraded to ("destination contract")
    /// @return The address of the destination token contract
    function upgradeDestination() external view returns(address) {
	return address(destination);
    }

    /// @dev The method will return true when the contract is serving upgrades and otherwise false
    /// @return The status of the upgrade as a boolean
    function isUpgradeActive() external view returns(bool) {
	return upgradeStatus;
    }

    /// @dev The method will return true when the contract is serving downgrades and otherwise false
    /// @return The status of the downgrade as a boolean
    function isDowngradeActive() external view returns(bool) {
	return downgradeStatus;
    }
    
    /// @dev A getter for the ratio of destination tokens to source tokens received when conducting an upgrade
    /// @return Two uint256, the first represents the numerator while the second represents
    /// the denominator of the ratio of destination tokens to source tokens allotted during the upgrade
    function ratio() external view returns(uint256, uint256) {
	return (numeratorRatio, denominatorRatio);
    }
    
    /// @dev A getter for the total amount of source tokens that have been upgraded to destination tokens.
    /// The value may not be strictly increasing if the downgrade Optional Ext. is implemented.
    /// @return The number of source tokens that have been upgraded to destination tokens
    function totalUpgraded() external view returns(uint256) {
	return sourceUpgradedTotal;
    }
    
    /// @dev A method to mock the upgrade call determining the amount of destination tokens received from an upgrade
    /// as well as the amount of source tokens that are left over as remainder
    /// @param sourceAmount The amount of source tokens that will be upgraded
    /// @return destinationAmount A uint256 representing the amount of destination tokens received if upgrade is called
    /// @return sourceRemainder A uint256 representing the amount of source tokens left over as remainder if upgrade is called
    function computeUpgrade(uint256 sourceAmount)
	public
	view
        returns (uint256 destinationAmount, uint256 sourceRemainder)
    {
	sourceRemainder = sourceAmount % (numeratorRatio / denominatorRatio);
	uint256 upgradeableAmount = sourceAmount - (sourceRemainder * RATIO_SCALE);
	destinationAmount = upgradeableAmount * (numeratorRatio / denominatorRatio);
    }
    
    /// @dev A method to mock the downgrade call determining the amount of source tokens received from a downgrade
    /// as well as the amount of destination tokens that are left over as remainder
    /// @param destinationAmount The amount of destination tokens that will be downgraded
    /// @return sourceAmount A uint256 representing the amount of source tokens received if downgrade is called
    /// @return destinationRemainder A uint256 representing the amount of destination tokens left over as remainder if upgrade is called
    function computeDowngrade(uint256 destinationAmount)
	public
	view
        returns (uint256 sourceAmount, uint256 destinationRemainder)
    {
	destinationRemainder = destinationAmount % (denominatorRatio / numeratorRatio);
	uint256 upgradeableAmount = destinationAmount - (destinationRemainder * RATIO_SCALE);
	sourceAmount = upgradeableAmount / (denominatorRatio / numeratorRatio);
    }
    
    /// @dev A method to conduct an upgrade from source token to destination token.
    /// The call will fail if upgrade status is not true, if approve has not been called
    /// on the source contract, or if sourceAmount is larger than the amount of source tokens at the msg.sender address.
    /// If the ratio would cause an amount of tokens to be destroyed by rounding/truncation, the upgrade call will
    /// only upgrade the nearest whole amount of source tokens returning the excess to the msg.sender address. 
    /// Emits the Upgrade event
    /// @param _to The address the destination tokens will be sent to upon completion of the upgrade
    /// @param sourceAmount The amount of source tokens that will be upgraded 
    function upgrade(address _to, uint256 sourceAmount) external {
	require(upgradeStatus == true, "SourceUpgrade: upgrade status is not active");
	(uint256 destinationAmount, uint256 sourceRemainder) = computeUpgrade(sourceAmount);
	sourceAmount -= sourceRemainder;
	require(sourceAmount > 0, "SourceUpgrade: disallow conversions of zero value");
	
	upgradedBalance[msg.sender] += sourceAmount;
	source.safeTransferFrom(
				msg.sender,
				address(this),
				sourceAmount
				);
	destination.safeTransfer(_to, destinationAmount);
	sourceUpgradedTotal += sourceAmount;
	emit Upgrade(msg.sender, _to, sourceAmount, destinationAmount);
    }
    
    /// @dev A method to conduct a downgrade from destination token to source token.
    /// The call will fail if downgrade status is not true, if approve has not been called
    /// on the destination contract, or if destinationAmount is larger than the amount of destination tokens at the msg.sender address.
    /// If the ratio would cause an amount of tokens to be destroyed by rounding/truncation, the downgrade call will only downgrade
    /// the nearest whole amount of destination tokens returning the excess to the msg.sender address. 
    ///  Emits the Downgrade event
    /// @param _to The address the source tokens will be sent to upon completion of the downgrade
    /// @param destinationAmount The amount of destination tokens that will be downgraded 
    function downgrade(address _to, uint256 destinationAmount) external {
	require(upgradeStatus == true, "SourceUpgrade: upgrade status is not active");
	(uint256 sourceAmount, uint256 destinationRemainder) = computeDowngrade(destinationAmount);
	destinationAmount -= destinationRemainder;
	require(destinationAmount > 0, "SourceUpgrade: disallow conversions of zero value");
	require(upgradedBalance[msg.sender] >= sourceAmount,
		"SourceUpgrade: can not downgrade more than previously upgraded"
		);
	
	upgradedBalance[msg.sender] -= sourceAmount;
	destination.safeTransferFrom(
				     msg.sender,
				     address(this),
				     destinationAmount
				     );
	source.safeTransfer(_to, sourceAmount);
	sourceUpgradedTotal -= sourceAmount;
	emit Downgrade(msg.sender, _to, sourceAmount, destinationAmount);
    }
}
