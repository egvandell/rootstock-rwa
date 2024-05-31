document.addEventListener('DOMContentLoaded', async function () {
  const connectButton = document.getElementById('connectButton');
//  const addAssetButton = document.getElementById('addAssetButton');
  const walletAddressDiv = document.getElementById('walletAddress');
  const assetsList = document.getElementById('assetsList');
  const assetNameInput = document.getElementById('assetName');
  const assetAddressInput = document.getElementById('assetAddress');
  const dataPointNameInput = document.getElementById('dataPointName');
  const dataPointValueInput = document.getElementById('dataPointValue');
  let provider, signer, assetManagerContract;
//  const contractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';   //hardhat url
//  const contractAddress = '0x08cd7c38AF7c4d5Aa6f14E704c7a18Fb1957F28E';   //testnet url1
  const contractAddress = '0x9b686A4f2E6C93E2765Aa8D7E33e11a9220277bb';   //testnet url2
  let contractABI = []; // Will be loaded from external file
  let networks = {};

  addAssetButton.addEventListener('click', async () => {
    await addAsset();
  });

  /**
   * Load contract ABI and network configuration from external files.
   */
  async function fetchExternalFiles() {
      let response = await fetch('AssetManager.json');
      const contractData = await response.json();
      contractABI = contractData.abi;

      response = await fetch('networks.json');
      networks = await response.json();
  }

  async function connectWallet() {
      if (window.ethereum) {
          try {
              await window.ethereum.request({ method: 'eth_requestAccounts' });
             provider = new ethers.providers.Web3Provider(window.ethereum);
              // const networkConfig = networks['hardhatLocal']; // Dynamically choose network based on some condition
              // provider = new ethers.providers.JsonRpcProvider(networkConfig.rpcUrls[0]);

              signer = provider.getSigner();
              assetManagerContract = new ethers.Contract(contractAddress, contractABI, signer);
              const address = await signer.getAddress();
              walletAddressDiv.innerHTML = `Connected account: ${address}`;
              await displayAssets(); // Display assets after connecting
          } catch (error) {
              console.error("Error connecting to MetaMask", error);
              walletAddressDiv.innerHTML = `Error: ${error.message}`;
          }
      } else {
          walletAddressDiv.innerHTML = 'Please install MetaMask!';
      }
  }

  async function displayAssets() {
      const assetCount = await assetManagerContract.nextAssetId();
      for (let i = 0; i < assetCount; i++) {
          const asset = await assetManagerContract.assets(i);
          const li = document.createElement('li');
          li.innerHTML = `Asset Name: ${asset.name}, Address: ${asset.assetAddress}`;
          assetsList.appendChild(li);
          asset.dataPoints.forEach((dp, index) => {
              const dpLi = document.createElement('li');
              dpLi.innerHTML = `--- Data Point ${index}: Name: ${dp.name}, Value: ${dp.value}, Needs Approval: ${dp.needsApproval}`;
              li.appendChild(dpLi);
          });
      }
  }

  async function addAsset() {
    const assetName = assetNameInput.value;
    const assetAddress = assetAddressInput.value;
    const dataPointName = dataPointNameInput.value;
    const dataPointValue = parseInt(dataPointValueInput.value, 10);

//    const dataPointTimestamp = Math.floor(Date.now() / 1000); // Get current timestamp in seconds


    console.log("Asset Name:", assetName);
    console.log("Asset Address:", assetAddress); // Verify if this is used in the contract function
    console.log("Data Point Name:", dataPointName);
    console.log("Data Point Value:", dataPointValue);

    if (isNaN(dataPointValue)) {
        alert("Invalid data point value. Please enter a valid number.");
        return;
    }

    const dataPoint = {name: dataPointName, value: dataPointValue, needsApproval: false};
    const initialDataPoints = [dataPoint];

    console.log("Data Point to be added:", dataPoint);
    console.log("Starting to add asset...");



    console.log("starting add asset");
    try {
        const tx = await assetManagerContract.registerAsset(assetName, initialDataPoints);
        console.log("starting add asset2");
        await tx.wait();
        alert("Asset added successfully!");
        await displayAssets(); // Refresh asset list
    } catch (error) {
        console.error("Error adding asset:", error);
        alert(`Failed to add asset: ${error.message}`);
    }
    console.log("finishing add asset");

}

  connectButton.addEventListener('click', async () => {
      await fetchExternalFiles(); // Load external files before connecting
      await connectWallet();
  });

});
