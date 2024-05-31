// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AssetManager is Ownable {
    struct DataPoint {
        string name;
        int256 value;
        bool needsApproval;
    }

    struct Asset {
        string name;
        address assetAddress;
        DataPoint[] dataPoints;
        bool exists;
    }

    mapping(uint256 => Asset) public assets;
    uint256 public nextAssetId;
    uint256 public deviationThreshold;

    event AssetCreated(uint256 assetId, string name);
    event DataPointAdded(uint256 assetId, string dataPointName, int256 value);
    event DataPointQueued(uint256 assetId, string dataPointName, int256 value);
    event DataPointApproved(uint256 assetId, string dataPointName, int256 value);

    constructor(uint256 _deviationThreshold) Ownable(msg.sender) {
        deviationThreshold = _deviationThreshold;
    }

     function registerAsset(string memory name, DataPoint[] memory initialDataPoints) public onlyOwner {
        Asset storage newAsset = assets[nextAssetId];
        newAsset.name = name;
        newAsset.exists = true;
        
        for (uint256 i = 0; i < initialDataPoints.length; i++) {
            newAsset.dataPoints.push(initialDataPoints[i]);
        }
        
        emit AssetCreated(nextAssetId, name);
        nextAssetId++;
    }

    function getAsset(uint256 assetId) external view returns 
        (string memory, address, bool) {
        Asset storage asset = assets[assetId];
        return (asset.name, asset.assetAddress, asset.exists);
    }

    function getDataPoint(uint256 assetId, uint256 index) external view returns 
        (string memory, int256, bool) {
        DataPoint storage dataPoint = assets[assetId].dataPoints[index];
        return (dataPoint.name, dataPoint.value, dataPoint.needsApproval);
    }

   function getLastValue(uint256 assetId, string memory dataPointName) internal view returns (int256, bool) {
        Asset storage asset = assets[assetId];
        if (asset.dataPoints.length > 0) {
            for (int256 i = int256(asset.dataPoints.length) - 1; i >= 0; i--) {
                DataPoint storage dataPoint = asset.dataPoints[uint256(i)];
                if (keccak256(abi.encodePacked(dataPoint.name)) == keccak256(abi.encodePacked(dataPointName))) {
                    return (dataPoint.value, true);
                }
            }
        }
        return (0, false);  // Return 0 and false if no previous data points are found
    }

    function addDataPoint(uint256 assetId, string memory dataPointName, int256 value) public onlyOwner {
        require(assets[assetId].exists, "Asset does not exist");
        Asset storage asset = assets[assetId];

        (int256 lastValue, bool found) = getLastValue(assetId, dataPointName);
        bool needsApproval = false;
        if (found) {
            int256 deviation = value - lastValue;
            needsApproval = isDeviationExcessive(deviation, lastValue);
        }

        DataPoint memory newDataPoint = DataPoint({
            name: dataPointName,
            value: value,
            needsApproval: needsApproval
        });

        asset.dataPoints.push(newDataPoint);
        if (needsApproval) {
            emit DataPointQueued(assetId, dataPointName, value);
        } else {
            emit DataPointAdded(assetId, dataPointName, value);
        }
    }

    function isDeviationExcessive(int256 deviation, int256 lastValue) internal view returns (bool) {
        // Calculate 3% of the last value using integer multiplication to avoid decimals
        // Since Solidity does not support decimals, we multiply first then divide by 100
        int256 threshold = (abs(lastValue) * int256(deviationThreshold)) / 100;

        return abs(deviation) > threshold;
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function approveDataPoint(uint256 assetId, uint256 dataPointIndex) public onlyOwner {
        require(assets[assetId].exists, "Asset does not exist");
        require(dataPointIndex < assets[assetId].dataPoints.length, "Invalid data point index");
        DataPoint storage dataPoint = assets[assetId].dataPoints[dataPointIndex];
        require(dataPoint.needsApproval, "Data point does not need approval");

        dataPoint.needsApproval = false;
        emit DataPointApproved(assetId, dataPoint.name, dataPoint.value);
    }
}
