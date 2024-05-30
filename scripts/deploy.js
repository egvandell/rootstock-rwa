async function main() {
    const [deployer] = await ethers.getSigners();
 
    console.log("Deploying contracts with the account:", deployer.address);
 
    const MyToken = await ethers.getContractFactory("AssetManager");
    const myToken = await MyToken.deploy();
 
    console.log("Contract address:", myToken.address);
    }
 
main().catch((error) => {
console.error(error);
    process.exitCode = 1;
});