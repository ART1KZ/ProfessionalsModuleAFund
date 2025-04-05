import {ethers} from "hardhat";

async function main() {;

    const [fond, tom, ben, rick, jack, startupA] = await ethers.getSigners();

    console.log("Deploying contracts with deployer:", fond.address);

    const SystemToken = await ethers.getContractFactory("SystemToken");
    const systemToken = await SystemToken.deploy([tom.address, ben.address, rick.address]);
    await systemToken.waitForDeployment();
    console.log("SystemToken deployed to:", systemToken.target);

    const WrapToken = await ethers.getContractFactory("WrapToken");
    const wrapToken = await WrapToken.deploy(fond.address);
    await wrapToken.waitForDeployment();
    console.log("WrapToken deployed to:", wrapToken.target);

    const Fund = await ethers.getContractFactory("VentureFund");
    const fund = await Fund.deploy(systemToken.target, wrapToken.target, tom.address, ben.address, rick.address);
    await fund.waitForDeployment();
    console.log("Fund deployed to:", fund.target);

    console.log("Initial PROFI balance per DAO member:", (await systemToken.balanceOf(tom.address)).toString());

    console.log("\n=== Users in Network ===");
    console.log("User: Tom, Address:", tom.address, "Status: DAO Member, Balance:", ethers.formatUnits(await systemToken.balanceOf(tom.address), 12), "PROFI");
    console.log("User: Ben, Address:", ben.address, "Status: DAO Member, Balance:", ethers.formatUnits(await systemToken.balanceOf(ben.address), 12), "PROFI");
    console.log("User: Rick, Address:", rick.address, "Status: DAO Member, Balance:", ethers.formatUnits(await systemToken.balanceOf(rick.address), 12), "PROFI");
    console.log("User: Jack, Address:", jack.address, "Status: Not DAO Member, Balance:", ethers.formatUnits(await wrapToken.balanceOf(jack.address), 12), "RTK");
    console.log("User: Startup A, Address:", startupA.address, "Status: Startup, Balance:", ethers.formatEther(await ethers.provider.getBalance(startupA.address)), "ETH");
    console.log("User: Fond, Address:", fond.address, "Status: Fond, Balance:", ethers.formatEther(await ethers.provider.getBalance(fond.address)), "ETH");

    console.log("\n=== Verifying Requirements ===");
    console.log("SystemToken total supply:", ethers.formatUnits(await systemToken.totalSupply(), 12), "PROFI");
    console.log("WrapToken total supply:", ethers.formatUnits(await wrapToken.totalSupply(), 12), "RTK");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });