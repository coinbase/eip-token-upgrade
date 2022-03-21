//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;

interface IEIP4931 {
    /// @dev A getter to determine the contract that is being upgraded from ("source contract")
    /// @return The address of the source token contract
    function upgradeSource() external view returns(address);

    /// @dev A getter to determine the contract that is being upgraded to ("destination contract")
    /// @return The address of the destination token contract
    function upgradeDestination() external view returns(address);

    /// @dev The method will return true when the contract is serving upgrades and otherwise false
    /// @return The status of the upgrade as a boolean
    function isUpgradeActive() external view returns(bool);

    /// @dev The method will return true when the contract is serving downgrades and otherwise false
    /// @return The status of the downgrade as a boolean
    function isDowngradeActive() external view returns(bool);

    /// @dev A getter for the ratio of destination tokens to source tokens received when conducting an upgrade
    /// @return Two uint256, the first represents the numerator while the second represents
    /// the denominator of the ratio of destination tokens to source tokens allotted during the upgrade
    function ratio() external view returns(uint256, uint256);

    /// @dev A getter for the total amount of source tokens that have been upgraded to destination tokens.
    /// The value may not be strictly increasing if the downgrade Optional Ext. is implemented.
    /// @return The number of source tokens that have been upgraded to destination tokens
    function totalUpgraded() external view returns(uint256);

    /// @dev A method to mock the upgrade call determining the amount of destination tokens received from an upgrade
    /// as well as the amount of source tokens that are left over as remainder
    /// @param sourceAmount The amount of source tokens that will be upgraded
    /// @return destinationAmount A uint256 representing the amount of destination tokens received if upgrade is called
    /// @return sourceRemainder A uint256 representing the amount of source tokens left over as remainder if upgrade is called
    function computeUpgrade(uint256 sourceAmount) external view
        returns (uint256 destinationAmount, uint256 sourceRemainder);

    /// @dev A method to mock the downgrade call determining the amount of source tokens received from a downgrade
    /// as well as the amount of destination tokens that are left over as remainder
    /// @param destinationAmount The amount of destination tokens that will be downgraded
    /// @return sourceAmount A uint256 representing the amount of source tokens received if downgrade is called
    /// @return destinationRemainder A uint256 representing the amount of destination tokens left over as remainder if upgrade is called
    function computeDowngrade(uint256 destinationAmount) external view
        returns (uint256 sourceAmount, uint256 destinationRemainder);

    /// @dev A method to conduct an upgrade from source token to destination token.
    /// The call will fail if upgrade status is not true, if approve has not been called
    /// on the source contract, or if sourceAmount is larger than the amount of source tokens at the msg.sender address.
    /// If the ratio would cause an amount of tokens to be destroyed by rounding/truncation, the upgrade call will
    /// only upgrade the nearest whole amount of source tokens returning the excess to the msg.sender address. 
    /// Emits the Upgrade event
    /// @param _to The address the destination tokens will be sent to upon completion of the upgrade
    /// @param sourceAmount The amount of source tokens that will be upgraded 
    function upgrade(address _to, uint256 sourceAmount) external;

    /// @dev A method to conduct a downgrade from destination token to source token.
    /// The call will fail if downgrade status is not true, if approve has not been called
    /// on the destination contract, or if destinationAmount is larger than the amount of destination tokens at the msg.sender address.
    /// If the ratio would cause an amount of tokens to be destroyed by rounding/truncation, the downgrade call will only downgrade
    /// the nearest whole amount of destination tokens returning the excess to the msg.sender address. 
    ///  Emits the Downgrade event
    /// @param _to The address the source tokens will be sent to upon completion of the downgrade
    /// @param destinationAmount The amount of destination tokens that will be downgraded 
    function downgrade(address _to, uint256 destinationAmount) external;

    /// @param _from Address that called upgrade
    /// @param _to Address that destination tokens were sent to upon completion of the upgrade
    /// @param amountSource Amount of source tokens that were upgraded
    /// @param amountDestination Amount of destination tokens sent to the _to address
    event Upgrade(address indexed _from, address indexed _to, uint256 amountSource, uint256 amountDestination);

    /// @param _from Address that called downgrade
    /// @param _to Address that source tokens were sent to upon completion of the downgrade
    /// @param amountSource Amount of source tokens sent to the _to address
    /// @param amountDestination Amount of destination tokens that were downgraded
    event Downgrade(address indexed _from, address indexed _to, uint256 amountSource, uint256 amountDestination);
}
