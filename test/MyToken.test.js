// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("MyToken", function () {
// it("Should deploy MyToken and assign the total supply to the owner", async function () {
//   const [owner] = await ethers.getSigners();

//   const MyToken = await ethers.getContractFactory("MyToken");
//   const myToken = await MyToken.deploy(1000);
//   await myToken.deployed();

//   expect((await myToken.totalSupply()).toString()).to.equal('1000');
//   expect((await myToken.balanceOf(owner.address)).toString()).to.equal('1000');
//     });
// });