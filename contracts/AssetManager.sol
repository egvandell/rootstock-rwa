// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

//import "hardhat/console.sol";

contract AssetManager is Ownable {
    struct DataPoint {
        string name;
        int256 value;
        string impactRule; 
        uint256 timestamp;
        bool needsApproval;
    }

    struct Asset {
        string name;
        DataPoint[] dataPoints;
        int256 value;
        bool exists;
    }

    mapping(uint256 => Asset) public assets;
    uint256 public nextAssetId;
    uint256 public deviationThreshold;

    event AssetCreated(uint256 assetId, string name);
    event DataPointAdded(uint256 assetId, string dataPointName, int256 value, uint256 timestamp);
    event DataPointQueued(uint256 assetId, string dataPointName, int256 value, uint256 timestamp);


    constructor(uint256 _deviationThreshold) Ownable(msg.sender) {
        deviationThreshold = _deviationThreshold;
    }

    function registerAsset(string memory name, int256 initialValue) public onlyOwner {
        Asset storage newAsset = assets[nextAssetId];
        newAsset.name = name;
        newAsset.value = initialValue;
        newAsset.exists = true;
        emit AssetCreated(nextAssetId, name);
        nextAssetId++;
    }

    function addDataPoint(
        uint256 assetId,
        string memory dataPointName,
        int256 value,
        string memory impactRule
    ) public onlyOwner {
        require(assets[assetId].exists, "Asset does not exist");
        Asset storage asset = assets[assetId];
        DataPoint memory newDataPoint = DataPoint({
            name: dataPointName,
            value: value,
            impactRule: impactRule,
            timestamp: block.timestamp,
            needsApproval: false
        });

        if (asset.dataPoints.length > 0) {
            DataPoint storage lastDataPoint = asset.dataPoints[asset.dataPoints.length - 1];
            if (isDeviationExcessive(lastDataPoint.value, value)) {
                newDataPoint.needsApproval = true;
                emit DataPointQueued(assetId, dataPointName, value, block.timestamp);
            } else {
                adjustAssetValue(asset, newDataPoint);
            }
        } else {
            adjustAssetValue(asset, newDataPoint);
        }

        asset.dataPoints.push(newDataPoint);
        emit DataPointAdded(assetId, dataPointName, value, block.timestamp);
    }

    function isDeviationExcessive(int256 lastValue, int256 newValue) internal view returns (bool) {
        int256 deviation = (lastValue - newValue) * 100 / lastValue;
        if (deviation < 0) {
            deviation = -deviation;
        }
        return deviation > int256(deviationThreshold);
    }

    function adjustAssetValue(Asset storage asset, DataPoint memory dataPoint) internal {
        if (keccak256(bytes(dataPoint.impactRule)) == keccak256(bytes("linear"))) {
            asset.value += dataPoint.value;
        } else if (keccak256(bytes(dataPoint.impactRule)) == keccak256(bytes("exponential"))) {
            asset.value += dataPoint.value * dataPoint.value;
        } else {
            // Default behavior or other rules
        }
    }

    function approveDataPoint(uint256 assetId, uint256 dataPointIndex) public onlyOwner {
        require(assets[assetId].exists, "Asset does not exist");
        Asset storage asset = assets[assetId];
        require(dataPointIndex < asset.dataPoints.length, "Invalid data point index");

        DataPoint storage dataPoint = asset.dataPoints[dataPointIndex];
        require(dataPoint.needsApproval, "Data point does not need approval");

        dataPoint.needsApproval = false;
        adjustAssetValue(asset, dataPoint);
    }
}
