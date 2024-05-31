const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AssetManager", function () {
    let AssetManager;
    let assetManager;
    let owner;
    let addr1;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        AssetManager = await ethers.getContractFactory("AssetManager");
        assetManager = await AssetManager.deploy(3); // 1% deviation threshold
        await assetManager.deployed();
    });


    it("Should deploy AssetManager and register an asset", async function () {
        const dataPoints = [
            // { name: "temperature", value: 72, idealValue: 72, impactRule: "temperature", timestamp: 0, needsApproval: false },
            // { name: "mileage", value: 0, idealValue: 0, impactRule: "mileage", timestamp: 0, needsApproval: false },
            // { name: "soil_quality", value: 65, idealValue: 65, impactRule: "soil_quality", timestamp: 0, needsApproval: false },
            { name: "humidity", value: 69, idealValue: 70, impactRule: "humidity", timestamp: 0, needsApproval: false }
        ];

        await assetManager.registerAsset("Car", dataPoints);
        const asset = await assetManager.assets(0);

        expect(asset.name).to.equal("Car");
        expect(asset.exists).to.equal(true);
    });

    it("Should register an asset", async function () {
        await assetManager.registerAsset("Car", []);
        
        const [name, assetAddress, exists] = await assetManager.getAsset(0);
        
        expect(name).to.equal("Car");
        expect(exists).to.equal(true);
    });
    
    it("Should add a data point", async function () {
        await assetManager.registerAsset("Car", []);
        
        // Add a new temperature data point
        await assetManager.addDataPoint(0, "temperature", 77);
        
        const [name, value, timestamp, needsApproval] = await assetManager.getDataPoint(0, 0);
        
        expect(name).to.equal("temperature");
        expect(value.toNumber()).to.equal(77);
    });
    
    it("Should queue a data point for approval when deviation is excessive", async function () {
        await assetManager.registerAsset("Car", []);
    
        // Initial value
        await assetManager.addDataPoint(0, "temperature", 72);
        
        // Add a new temperature data point with excessive deviation
        await assetManager.addDataPoint(0, "temperature", 90);
        
        const [, , , needsApproval] = await assetManager.getDataPoint(0, 1); // Make sure index 1 is correct
        
        expect(needsApproval).to.be.true; // Check if the data point requires approval
    });
        
});
