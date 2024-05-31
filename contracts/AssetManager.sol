// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AssetManager is Ownable {
    struct DataPoint {
        string name;
        int256 value;
        int256 idealValue;
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
    event DataPointApproved(uint256 assetId, string dataPointName, int256 value, uint256 timestamp);

    constructor(uint256 _deviationThreshold) Ownable(msg.sender) {
        deviationThreshold = _deviationThreshold;
    }

    function registerAsset(string memory name, int256 initialValue, DataPoint[] memory initialDataPoints) public onlyOwner {
        Asset storage newAsset = assets[nextAssetId];
        newAsset.name = name;
        newAsset.value = initialValue;
        newAsset.exists = true;
        
        for (uint256 i = 0; i < initialDataPoints.length; i++) {
            newAsset.dataPoints.push(initialDataPoints[i]);
        }
        
        emit AssetCreated(nextAssetId, name);
        nextAssetId++;
    }

    function addDataPoint(
        uint256 assetId,
        string memory dataPointName,
        int256 value
    ) public onlyOwner {
        require(assets[assetId].exists, "Asset does not exist");
        Asset storage asset = assets[assetId];
        bool found = false;
        uint256 dataPointIndex;

        for (uint256 i = 0; i < asset.dataPoints.length; i++) {
            if (keccak256(bytes(asset.dataPoints[i].name)) == keccak256(bytes(dataPointName))) {
                dataPointIndex = i;
                found = true;
                break;
            }
        }

        require(found, "Data point not found in asset");

        DataPoint storage dataPoint = asset.dataPoints[dataPointIndex];
        int256 deviation = value - dataPoint.idealValue;
        
        if (isDeviationExcessive(deviation)) {
            dataPoint.needsApproval = true;
            dataPoint.value = value;
            emit DataPointQueued(assetId, dataPointName, value, block.timestamp);
            return;
        }

        dataPoint.value = value;
        emit DataPointAdded(assetId, dataPointName, value, block.timestamp);
        adjustAssetValue(asset, dataPoint, deviation);
    }

    function isDeviationExcessive(int256 deviation) internal view returns (bool) {
        if (deviation < 0) {
            deviation = -deviation;
        }
        return deviation > int256(deviationThreshold);
    }

    function adjustAssetValue(Asset storage asset, DataPoint memory dataPoint, int256 deviation) internal {
        if (keccak256(bytes(dataPoint.impactRule)) == keccak256(bytes("temperature"))) {
            if (deviation != 0) {
                asset.value -= (deviation * 200) / 5; // 2% decrease per 5 degrees deviation
            }
        } else if (keccak256(bytes(dataPoint.impactRule)) == keccak256(bytes("mileage"))) {
            if (deviation > 0) {
                asset.value -= (deviation * 100) / 1000; // 1% decrease per 1000 miles deviation
            }
        } else if (keccak256(bytes(dataPoint.impactRule)) == keccak256(bytes("soil_quality"))) {
            if (deviation != 0) {
                asset.value -= (deviation * 50) / 1; // 0.5% decrease per 0.1 unit deviation
            }
        } else if (keccak256(bytes(dataPoint.impactRule)) == keccak256(bytes("humidity"))) {
            if (dataPoint.value > 70) {
                asset.value -= ((dataPoint.value - 70) * 50) / 1; // 0.5% decrease per percentage point above 70%
            }
        } else {
            // Algorithm will need to be developed
            asset.value = asset.value;
        }
    }

    function approveDataPoint(uint256 assetId, uint256 dataPointIndex) public onlyOwner {
        require(assets[assetId].exists, "Asset does not exist");
        Asset storage asset = assets[assetId];
        require(dataPointIndex < asset.dataPoints.length, "Invalid data point index");

        DataPoint storage dataPoint = asset.dataPoints[dataPointIndex];
        require(dataPoint.needsApproval, "Data point does not need approval");

        dataPoint.needsApproval = false;
        emit DataPointApproved(assetId, dataPoint.name, dataPoint.value, dataPoint.timestamp);

        int256 deviation = dataPoint.value - dataPoint.idealValue;
        adjustAssetValue(asset, dataPoint, deviation);
    }
}
