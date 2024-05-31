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
        assetManager = await AssetManager.deploy(100); // 1% deviation threshold
        await assetManager.deployed();
    });


    it("Should deploy AssetManager and register an asset", async function () {
        const dataPoints = [
            { name: "temperature", value: 72, idealValue: 72, impactRule: "temperature", timestamp: 0, needsApproval: false },
            { name: "mileage", value: 0, idealValue: 0, impactRule: "mileage", timestamp: 0, needsApproval: false },
            { name: "soil_quality", value: 65, idealValue: 65, impactRule: "soil_quality", timestamp: 0, needsApproval: false },
            { name: "humidity", value: 69, idealValue: 70, impactRule: "humidity", timestamp: 0, needsApproval: false }
        ];

        await assetManager.registerAsset("Car", 1000, dataPoints);
        const asset = await assetManager.assets(0);

        expect(asset.name).to.equal("Car");
        expect(asset.value.toString()).to.equal(ethers.BigNumber.from(1000).toString());
        expect(asset.exists).to.equal(true);
    });

    it("Should add a data point and adjust the asset value", async function () {
        const dataPoints = [
            { name: "temperature", value: 72, idealValue: 72, impactRule: "temperature", timestamp: 0, needsApproval: false },
            { name: "mileage", value: 0, idealValue: 0, impactRule: "mileage", timestamp: 0, needsApproval: false },
            { name: "soil_quality", value: 65, idealValue: 65, impactRule: "soil_quality", timestamp: 0, needsApproval: false },
            { name: "humidity", value: 69, idealValue: 70, impactRule: "humidity", timestamp: 0, needsApproval: false }
        ];
    
        await assetManager.registerAsset("Car", 1000, dataPoints);
    
        // Add a new temperature data point
        await assetManager.addDataPoint(0, "temperature", 77);
        const asset = await assetManager.assets(0);
    
        const expectedValue = 1000 - (5 * 200) / 5; // Calculating expected value: 1000 - 200
        expect(asset.value.toString()).to.equal(ethers.BigNumber.from(expectedValue).toString());
    });

    it("Should queue a data point for approval when deviation is excessive", async function () {
        const dataPoints = [
            { name: "temperature", value: 72, idealValue: 72, impactRule: "temperature", timestamp: 0, needsApproval: false },
            { name: "mileage", value: 0, idealValue: 0, impactRule: "mileage", timestamp: 0, needsApproval: false },
            { name: "soil_quality", value: 65, idealValue: 65, impactRule: "soil_quality", timestamp: 0, needsApproval: false },
            { name: "humidity", value: 69, idealValue: 70, impactRule: "humidity", timestamp: 0, needsApproval: false }
        ];

        await assetManager.registerAsset("Car", 1000, dataPoints);

        // Add a new temperature data point with excessive deviation
        const tx = await assetManager.addDataPoint(0, "temperature", 90);

        // Verify that the DataPointQueued event was emitted
        await expect(tx)
            .to.emit(assetManager, 'DataPointQueued')
            .withArgs(0, "temperature", 90, await ethers.provider.getBlockNumber());
    });


    // it("Should approve a data point and adjust the asset value", async function () {
    //     const dataPoints = [
    //         { name: "temperature", value: 72, idealValue: 72, impactRule: "temperature", timestamp: 0, needsApproval: false },
    //         { name: "mileage", value: 0, idealValue: 0, impactRule: "mileage", timestamp: 0, needsApproval: false },
    //         { name: "soil_quality", value: 65, idealValue: 65, impactRule: "soil_quality", timestamp: 0, needsApproval: false },
    //         { name: "humidity", value: 69, idealValue: 70, impactRule: "humidity", timestamp: 0, needsApproval: false }
    //     ];

    //     await assetManager.registerAsset("Car", 1000, dataPoints);

    //     // Add a new temperature data point with excessive deviation
    //     await assetManager.addDataPoint(0, "temperature", 90);

    //     // Approve the data point
    //     await assetManager.approveDataPoint(0, 0);
    //     const asset = await assetManager.assets(0);

    //     expect(asset.value).to.equal(ethers.BigNumber.from(920)); // 18°F deviation results in 7.2% decrease (18 / 5 * 2%)
    // });
});
