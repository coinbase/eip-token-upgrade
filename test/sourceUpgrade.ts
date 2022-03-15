
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { PermissionlessERC20 } from "../@types/generated/PermissionlessERC20";
import { SourceUpgrade } from "../@types/generated/SourceUpgrade";
import { SourceUpgrade__factory } from "../@types/generated/factories/SourceUpgrade__factory";
import { expect } from "chai";
const hre = require("hardhat");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const UPGRADE_STATUS = true;
const DOWNGRADE_STATUS = true;
const NUMERATOR_RATIO = "1000000000000000000";
const DENOMINATOR_RATIO = "1000000000000000000";

describe("SourceUprade", function() {
  let owner1: SignerWithAddress;
  let sourceERC20: PermissionlessERC20;
  let destinationERC20: PermissionlessERC20;
  let sourceUpgrade: SourceUpgrade;
  let sourceUpgradeFactory: SourceUpgrade__factory;

  beforeEach(async () => {
      [owner1] = await hre.ethers.getSigners();
      const ERC20Factory = await hre.ethers.getContractFactory("PermissionlessERC20");
      sourceERC20 = await ERC20Factory.deploy("Source", "SOURCE");
      destinationERC20 = await ERC20Factory.deploy("Destination", "DESTINATION");
      sourceUpgradeFactory = await hre.ethers.getContractFactory("SourceUpgrade");
      sourceUpgrade = await sourceUpgradeFactory.deploy(sourceERC20.address, destinationERC20.address, UPGRADE_STATUS, DOWNGRADE_STATUS, NUMERATOR_RATIO, DENOMINATOR_RATIO); 
  });
    describe("constructor", () => {
	it("reverts if source and destination addresses are the same", async () => {
	    await expect(sourceUpgradeFactory.deploy(sourceERC20.address, sourceERC20.address, UPGRADE_STATUS, DOWNGRADE_STATUS, NUMERATOR_RATIO, DENOMINATOR_RATIO))
		.to.be.revertedWith(
		    "SourceUpgrade: source and destination addresses are the same"
		);
	});
	
	it("reverts if source is zero address", async () => {
	    await expect(sourceUpgradeFactory.deploy(ZERO_ADDRESS, destinationERC20.address, UPGRADE_STATUS, DOWNGRADE_STATUS, NUMERATOR_RATIO, DENOMINATOR_RATIO))
		.to.be.revertedWith(
		    "SourceUpgrade: source address cannot be zero address"
		);
	});
	
	it("reverts if destination is zero address", async () => {
	    await expect(sourceUpgradeFactory.deploy(sourceERC20.address, ZERO_ADDRESS, UPGRADE_STATUS, DOWNGRADE_STATUS, NUMERATOR_RATIO, DENOMINATOR_RATIO))
		.to.be.revertedWith(
		    "SourceUpgrade: destination address cannot be zero address"
		);
	});
	
	it("reverts if numerator of ratio is zero", async () => {
	    await expect(sourceUpgradeFactory.deploy(sourceERC20.address, destinationERC20.address,  UPGRADE_STATUS, DOWNGRADE_STATUS, 0, DENOMINATOR_RATIO))
		.to.be.revertedWith(
		    "SourceUpgrade: numerator of ratio cannot be zero"
		);
	});

	it("reverts if denominator of ratio is zero", async () => {
	    await expect(sourceUpgradeFactory.deploy(sourceERC20.address, destinationERC20.address,  UPGRADE_STATUS, DOWNGRADE_STATUS, NUMERATOR_RATIO, 0))
		.to.be.revertedWith(
		    "SourceUpgrade: denominator of ratio cannot be zero"
		);
	});
	
	it("sets the correct parameters", async () => {
	    expect(await sourceUpgrade.upgradeSource()).to.equal(sourceERC20.address);
	    expect(await sourceUpgrade.upgradeDestination()).to.equal(destinationERC20.address);
	    expect((await sourceUpgrade.ratio()).toString()).to.equal([NUMERATOR_RATIO, DENOMINATOR_RATIO].toString());
	    expect((await sourceUpgrade.isUpgradeActive())).to.equal(true);
	    expect((await sourceUpgrade.isDowngradeActive())).to.equal(true);
	});
    });
    
    describe("upgrade", () => {
	it("reverts if transferFrom fails", async () => {
	    await expect(sourceUpgrade.upgrade(owner1.address, 1))
		.to.be.revertedWith(
		    "ERC20: insufficient allowance"
		);
	});
	
	it("reverts if transfer fails", async () => {
	    await sourceERC20.mint(owner1.address, 1);
	    await sourceERC20.approve(sourceUpgrade.address, 1);
	    await expect(sourceUpgrade.upgrade(owner1.address, 1))
		.to.be.revertedWith(
		    "ERC20: transfer amount exceeds balance"
		);
	});
	
	it("upgrades source token to destination token", async () => {
	    await sourceERC20.mint(owner1.address, 1);
	    await destinationERC20.mint(sourceUpgrade.address, 1);
	    await sourceERC20.approve(sourceUpgrade.address, 1);
	    
	    expect(await sourceERC20.balanceOf(owner1.address)).to.equal(1);
	    expect(await sourceERC20.totalSupply()).to.equal(1);
	    expect(await destinationERC20.balanceOf(owner1.address)).to.equal(0);
	    expect(await destinationERC20.totalSupply()).to.equal(1);
	    expect(await sourceUpgrade.totalUpgraded()).to.equal(0);
	    
	    await expect(sourceUpgrade.upgrade(owner1.address, 1))
		.to.emit(sourceUpgrade, "Upgrade")
		.withArgs(owner1.address, owner1.address, 1, 1);
	    
	    expect(await sourceERC20.balanceOf(owner1.address)).to.equal(0);
	    expect(await sourceERC20.totalSupply()).to.equal(1);
	    expect(await destinationERC20.balanceOf(owner1.address)).to.equal(1);
	    expect(await destinationERC20.totalSupply()).to.equal(1);
	    expect(await sourceUpgrade.totalUpgraded()).to.equal(1);
	});

	it("downgrades destination token to source token after an initial upgrade", async () => {
	    await sourceERC20.mint(owner1.address, 1);
	    await destinationERC20.mint(sourceUpgrade.address, 1);
	    await sourceERC20.approve(sourceUpgrade.address, 1);
	    
	    expect(await sourceERC20.balanceOf(owner1.address)).to.equal(1);
	    expect(await sourceERC20.totalSupply()).to.equal(1);
	    expect(await destinationERC20.balanceOf(owner1.address)).to.equal(0);
	    expect(await destinationERC20.totalSupply()).to.equal(1);
	    
	    await expect(sourceUpgrade.upgrade(owner1.address, 1))
		.to.emit(sourceUpgrade, "Upgrade")
		.withArgs(owner1.address, owner1.address, 1, 1);
	    
	    expect(await sourceERC20.balanceOf(owner1.address)).to.equal(0);
	    expect(await sourceERC20.totalSupply()).to.equal(1);
	    expect(await destinationERC20.balanceOf(owner1.address)).to.equal(1);
	    expect(await destinationERC20.totalSupply()).to.equal(1);
	    expect(await sourceUpgrade.totalUpgraded()).to.equal(1);
	    
	    await destinationERC20.approve(sourceUpgrade.address, 1);
	    await expect(sourceUpgrade.downgrade(owner1.address, 1))
		.to.emit(sourceUpgrade, "Downgrade")
		.withArgs(owner1.address, owner1.address, 1, 1);

	    expect(await sourceERC20.balanceOf(owner1.address)).to.equal(1);
	    expect(await sourceERC20.totalSupply()).to.equal(1);
	    expect(await destinationERC20.balanceOf(owner1.address)).to.equal(0);
	    expect(await destinationERC20.totalSupply()).to.equal(1);
	    expect(await sourceUpgrade.totalUpgraded()).to.equal(0);
	    
	});
    });
});
