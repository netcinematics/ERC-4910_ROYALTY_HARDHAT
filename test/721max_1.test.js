const { time, loadFixture, } = require("@nomicfoundation/hardhat-network-helpers");
// const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
// const { ethers } = require('hardhat'); //for zero address
const { expect } = require("chai");
  // https://hardhat.org/hardhat-network-helpers/docs/reference
  // https://hardhat.org/hardhat-chai-matchers/docs/overview


  //PAYOUT TEST VARIABLES.
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  // const accAdmin = accounts[0];
  // const accSeller = accounts[1];
  // const accBuyer = accounts[2];
  // const accReceiver = accounts[3];
  // const accOtherBuyer = accounts[4];
  // const accSomeOther = accounts[5];

  // const costOfNFT = 100;
  // const token_1 = 1;
  const token_1_1 = 2;
  // const token_1_1_1 = 3;
  // const token_1_1_2 = 4;
  // const token_2 = 5;
  // const token_not_exists = 999;

  // let token;
  // let someToken1;
  // let someToken2;
  // let paymentModule;



describe("RoyaltyBearingToken: RBT:ROYALTY PAYOUT TESTS", function () {
  async function deployRoyaltyPayoutFIXTURE() { //define fixture
    const timestamp = (await time.latest());
    console.log('RBT1 Constructor');
    // Contracts are deployed using the first signer/account by default
    const [owner, account2, account3 ] = await ethers.getSigners();
    console.log("OWNER:",owner.address);
    console.log("ADDRESS2:",account2.address);


    //RBT - TOKEN - token
    const RoyaltyBearingToken = await ethers.getContractFactory("RoyaltyBearingToken");
    const RBT1 = await RoyaltyBearingToken.deploy('RBT1','TEST111','baseURI1',owner.address,8);
    
    const RoyaltyModule = await ethers.getContractFactory("RoyaltyModule");
    const royaltyModule = await RoyaltyModule.deploy(
      RBT1.address,
      account2.address, //TT Royalty, ?
      1000, // royaltySplitTT 1000 = 10%,
      500, //minRoyaltySplit
      5, //maxSubAccount      
    );

  //   before(async () => { //EXAMPLE 1 from RBT TEST
  //     someToken1 = await SomeERC20_1.deployed();
  //     someToken2 = await SomeERC20_2.deployed();
  //     token = await RoyaltyBearingToken.deployed();

  //     paymentModule = await PaymentModule.deployed();

  //     //Mint some  ERC20 tokens
  //     await someToken1.mint(accBuyer, 100000000, { from: accAdmin });
  //     await someToken2.mint(accBuyer, 100000000, { from: accAdmin });
  //     await someToken2.mint(accOtherBuyer, 100000000, { from: accAdmin });
  // });

  // EXAMPLE 2 from DEPLOY_CONTRACTS
  // const ERC20_1 = await deployer.deploy(SomeERC20_1, 'Some test token #1', 'ST1');
  // const ERC20_2 = await deployer.deploy(SomeERC20_2, 'Some test token #2', 'ST2');
  
    //  const token = await RoyaltyBearingToken.deploy('RBT2','TEST2','baseURI2',owner.address,8);
  // const token = await deployer.deploy(
  //     RoyaltyBearingToken,
  //     'RoyaltyBearingToken',
  //     'RBT',
  //     'https:\\\\some.base.url\\',
  //     ['ETH', 'ST1', 'ST2'],
  //     ['0x0000000000000000000000000000000000000000', ERC20_1.address, ERC20_2.address],
  //     accounts[0],
  //     100, //numGenerations
  // );

  // const royaltyModule = await deployer.deploy(
  //     RoyaltyModule,
  //     token.address,
  //     accounts[0], //TT Royalty,
  //     1000, // royaltySplitTT 1000 = 10%,
  //     500, //minRoyaltySplit
  //     5, //maxSubAccount
  // );
  // const paymentModule = await deployer.deploy(
  //     PaymentModule,
  //     token.address,
  //     10, //maxListingNumber
  // );

    await RBT1.init(royaltyModule.address);
      //TEST-VARIABLES
      // accAdmin = owner;
  // await token.init(royaltyModule.address, paymentModule.address);
    // token.init(ZERO_ADDRESS, ZERO_ADDRESS, { from: accAdmin })
    return { RBT1, royaltyModule, owner, account2, account3 };
  }

  describe("Deploy Payout Contract:", function() {
    it("should init RBT and ROYALTY", async function () {
      const {RBT1, royaltyModule} = await loadFixture(deployRoyaltyPayoutFIXTURE);
      expect(RBT1); //exists
      expect(royaltyModule); //attached royalty RA lookup 
      console.log("NAME:",await RBT1.name(),"SYMBOL:",await RBT1.symbol());
      expect(await RBT1.name()).to.equal('RBT1');
      expect(await RBT1.symbol()).to.equal('TEST111');
      const balance = await ethers.provider.getBalance(RBT1.address)
      console.log("BALANCE:", balance);
      expect(balance).to.equal(0); 
    })
  });

  describe('royaltyPayOut restrictions', async () => {
    it('second init - ERROR', async () => {
      const {RBT1} = await loadFixture(deployRoyaltyPayoutFIXTURE);      
      await expect(RBT1.init(ZERO_ADDRESS)).to.be.revertedWith("Init was called before");
      // await RBT1.init(ZERO_ADDRESS /*, ZERO_ADDRESS, { from: owner }*/ )
      // await truffleAssert.reverts(token.init(ZERO_ADDRESS, ZERO_ADDRESS, { from: accAdmin }), 'Init was called before');
    });
    it('Success payout', async () => {
      const {RBT1} = await loadFixture(deployRoyaltyPayoutFIXTURE);
      // expect(RBT1); //NAME and SYMBOL and BALANCE
      const ra_1_1_before = await RBT1.getRoyaltyAccount(token_1_1);
      // const ra_1_1_before = await token.getRoyaltyAccount(token_1_1);
      // await token.royaltyPayOut(2, accBuyer, accBuyer, 1, { from: accBuyer });
      // const ra_1_1_after = await token.getRoyaltyAccount(token_1_1);
      // assert.equal(ra_1_1_before.subaccounts[0].royaltyBalance - 1, ra_1_1_after.subaccounts[0].royaltyBalance, 'Royalty changed after payout');
    });
    xit('Payout TT royalty from (3)', async () => {
      const ra_1_1_1_before = await token.getRoyaltyAccount(token_1_1_1);
      await token.royaltyPayOut(token_1_1_1, accAdmin, accAdmin, ra_1_1_1_before.subaccounts[1].royaltyBalance, { from: accAdmin });
      const ra_1_1_1_after = await token.getRoyaltyAccount(token_1_1_1);
      assert.equal(ra_1_1_1_after.subaccounts[1].royaltyBalance, 0);
    });

    xit('Only subaccount owner can run payout', async () => {
  
        await truffleAssert.reverts(token.royaltyPayOut(token_1, accBuyer, accBuyer, 1, { from: accOtherBuyer }), 'Sender must be subaccount owner');
        await truffleAssert.reverts(token.royaltyPayOut(token_1_1, accBuyer, accBuyer, 1, { from: accOtherBuyer }), 'Sender must be subaccount owner');
        await truffleAssert.reverts(token.royaltyPayOut(token_1_1_1, accBuyer, accBuyer, 1, { from: accOtherBuyer }), 'Sender must be subaccount owner');
    });
    xit('Payout limited to royalty balance', async () => {
        await truffleAssert.reverts(token.royaltyPayOut(token_1_1, accBuyer, accBuyer, 999, { from: accBuyer }), 'Insufficient royalty balance');
    });
    xit('Payout for non exist NFT restricted', async () => {
        await truffleAssert.reverts(token.royaltyPayOut(token_not_exists, accBuyer, accBuyer, 1, { from: accBuyer }), 'Subaccount not found');
    });
    xit('Success payout', async () => {
        const ra_1_1_before = await token.getRoyaltyAccount(token_1_1);
        await token.royaltyPayOut(2, accBuyer, accBuyer, 1, { from: accBuyer });
        const ra_1_1_after = await token.getRoyaltyAccount(token_1_1);
        assert.equal(ra_1_1_before.subaccounts[0].royaltyBalance - 1, ra_1_1_after.subaccounts[0].royaltyBalance, 'Royalty changed after payout');
    });
  });
  



}); //END ROYALTY TESTS

describe("RoyaltyBearingToken: RBT:721 TESTS", function () {
  async function deployGenericTestFixture() { //define fixture
    const timestamp = (await time.latest());
    console.log('RBT1 Constructor');
    // Contracts are deployed using the first signer/account by default
    const [owner, account2, account3 ] = await ethers.getSigners();
    console.log("OWNER:",owner.address);
    console.log("ADDRESS2:",account2.address);
    const RoyaltyBearingToken = await ethers.getContractFactory("RoyaltyBearingToken");
    const RBT1 = await RoyaltyBearingToken.deploy('RBT1','TEST111','baseURI1',owner.address,8);
    return { RBT1, timestamp, owner, account2, account3 };
  }

describe("Deploy Contract:", function() {
  it("should return CONTRACT with NAME and SYMBOL", async function () {
    const {RBT1, timestamp} = await loadFixture(deployGenericTestFixture);
    expect(RBT1); //NAME and SYMBOL and BALANCE
    console.log("NAME:",await RBT1.name(),"SYMBOL:",await RBT1.symbol());
    expect(await RBT1.name()).to.equal('RBT1');
    expect(await RBT1.symbol()).to.equal('TEST111');
    const balance = await ethers.provider.getBalance(RBT1.address)
    console.log("BALANCE:", balance);
    expect(balance).to.equal(0); 
    console.log("TIMESTAMP:",timestamp);
  })
});

describe("MINT behaviors:", function(){
  xit("Should auto MINT (2) IDz on deploy to OWNER", async function () {
    const {RBT1,owner,account2} = await loadFixture(deployGenericTestFixture);
    expect(await RBT1.totalSupply()).to.equal(2);
    expect(await RBT1.ownerOf(1)).to.equal(owner.address);
  });
  
  xit("Should MINT owner (3) and address2 (4), but not addr2 twice", async function () {
    const {RBT1, owner, account2} = await loadFixture(deployGenericTestFixture);
    const safeMintRBT = await RBT1.safeMintRBT(owner.address,2);
    expect(safeMintRBT);
    expect(await RBT1.totalSupply()).to.equal(3);
    expect(await RBT1.ownerOf(3)).to.equal(owner.address);
    expect(await RBT1.safeMintRBT(account2.address,1)).to.not.be.reverted;
    expect(await RBT1.totalSupply()).to.equal(4);
    expect(await RBT1.ownerOf(4)).to.equal(account2.address);
    await expect(RBT1.safeMintRBT(account2.address,2)).to.be.revertedWith(
      "one mint per wallet"); 
    await expect(RBT1.safeMintRBT(account2.address,0)).to.be.revertedWith(
      "bad data");
    // await expect(RBT1.safeMintRBT(ethers.constants.ZeroAddress,1)).to.be.revertedWith(
    await expect(RBT1.safeMintRBT("0x0000000000000000000000000000000000000000",1)).to.be.revertedWith(
      "bad address");
    expect(await RBT1.totalSupply()).to.equal(4);    
  });

  xit("Should revert MAX-MINT:", async function () {
    //New fixture, for a different deployment.
    const RoyaltyBearingToken = await ethers.getContractFactory("RoyaltyBearingToken");
    const RBT1 = await RoyaltyBearingToken.deploy('RBT1','TESTMAX');
    const [owner, account2] = await ethers.getSigners();
    let maxMint = await RBT1.maxMintSupply();
    let startSupply = await RBT1.totalSupply();
    console.log("MAX-MINT-AMOUNT:", maxMint);
    console.log("START-SUPPLY:",startSupply);
    let safeMintRBT = null; //owner is allowed to mint multiple for this test
    for (let i = 1; i <= maxMint-startSupply; i++) { //console.log(i);
        safeMintRBT = await RBT1.safeMintRBT(owner.address,2);
    }
    console.log("END-SUPPLY:",await RBT1.totalSupply());
    expect(await RBT1.safeMintRBT(owner.address,1)).to.be.revertedWith(
      "MAX-MINT reached");
    console.log("OVER-SUPPLY-1:",await RBT1.totalSupply());
    await expect(RBT1.safeMintRBT(account2.address,2)).to.be.revertedWith(
      "MAX-MINT reached");
    console.log("OVER-SUPPLY-2:",await RBT1.totalSupply());
    await expect(await RBT1.ownerOf(await RBT1.totalSupply())).to.equal(owner.address);
    const overdraft = await RBT1.totalSupply()+1;
    expect(RBT1.ownerOf(overdraft)).to.be.revertedWith("ERC721: invalid token ID");
  }); 
});

describe("NON-TRANSFERABLE", function () {
  xit("Should not transfer:", async function () {
    const {RBT1, owner, account2} = await loadFixture(deployGenericTestFixture);
    await expect(RBT1.transferFrom(owner.address,account2.address,2)).to.be.revertedWith(
      "SBT can only be burned");
    expect(await RBT1.ownerOf(2)).to.equal(owner.address);
    // await RBT1.transferFrom(owner.address,account2.address,2); //Working Transfer
  });
});    

describe("PAUSABLE:", function () {
  xit("Should be pausable by owner, not addr2, and should resume.", async function () {
    const {RBT1, account2} = await loadFixture(deployGenericTestFixture);
    expect(await RBT1.paused()).to.equal(false);
    await expect(RBT1.pause(true)).not.to.be.reverted;
    expect(await RBT1.paused()).to.equal(true);
    await expect(RBT1.safeMintRBT(account2.address,2)).to.be.revertedWith(
      "contract is paused");
    expect(await RBT1.totalSupply()).to.equal(2);
    await expect(RBT1.connect(account2).pause(false)).to.be.revertedWith(
      "Ownable: caller is not the owner" );  
    await expect(RBT1.pause(false)).not.to.be.reverted;
    expect(await RBT1.paused()).to.equal(false);      
      
  });
});

describe("BURNABLE:", function () {
  xit("Should burn by owner, not by non owner", async function () {
    const {RBT1, account2} = await loadFixture(deployGenericTestFixture);
    await expect(RBT1.burn(1)).to.be.revertedWith("cannot burn owner");
    await expect(RBT1.connect(account2).burn(8)).to.be.revertedWith("nonexistent token");
    expect(await RBT1.connect(account2).safeMintRBT(account2.address,1)).to.not.be.reverted;
    expect(await RBT1.totalSupply()).to.equal(3);
    await expect(RBT1.connect(account2).burn(3)).not.to.be.reverted;
    await expect(RBT1.ownerOf(3)).to.be.revertedWith("ERC721: invalid token ID");
    await expect(RBT1.connect(account2).burn(2)).to.be.revertedWith("non owner");
  });
});

describe("VALIDATABLE:", function () {
  xit("Should validate existing IDz, and non existing", async function () {
    const {RBT1, account2, account3} = await loadFixture(deployGenericTestFixture);
    expect(await RBT1.connect(account2).safeMintRBT(account2.address,1)).to.not.be.reverted;
    expect(await RBT1.totalSupply()).to.equal(3);
    expect(await RBT1.connect(account2).validateIDz(account2.address)).to.equal(true);
    expect(await RBT1.connect(account2).validateIDz(account3.address)).to.equal(false);
    await expect(RBT1.connect(account2).burn(3)).to.not.be.reverted;
    expect(await RBT1.connect(account2).validateIDz(account2.address)).to.equal(false);
  });
});

describe("Events", function () {
  xit("Should emit an event on Minted and Burned", async function () {
    const { RBT1, account2 } = await loadFixture( deployGenericTestFixture );
    await expect(RBT1.safeMintRBT(account2.address,1)).to.emit(RBT1, "Minted");
    await expect(RBT1.connect(account2).burn(3)).to.emit(RBT1, "Burned");
  });
});

}); //END-RoyaltyBearingToken
    

/**************************************\
 * DESCRIPTION: 
 * Minimum RBT in Hardhat.
 O write tests to core 4910 functions
 O deploy
 O init
 O clear balances
 O transfer tests
 O distributePayment()
 O royaltyPayout()
 O Scenario
 O TARGET: distributePayment - replacementFn.

 ***************************************/

//TODO: 


//PREVIOUSLY...
//X 1 DEPLOY on Remix (coverage) //O can paused be changed //URL?
    //- change batch size on beforeTransfer?
    //- connect mumbai wallet 0xD5a 800001 DEVAU or 0x46f  
    //- contract: PIRATEorNINJA 
    //- deploy "DIDzv1", "100"
    //- https://testnets.opensea.io/0xd5A0c036B0693A156042F0D3bFD84174B42cfDC7
    //- LOOKAT: name & symbol, baseURI, totalSupply, owmerOf(1), maxMintSupply,
    //- tokenURI(1): json ipfs - requires tokenURI to render card.
    //- SOMETIMES IMAGE TAKES TIME TO LOAD BECAUSE OF METADATA.
    //O FIX timestamp and address string
    //O REVIEW all interfaces.
    //- Review deploy to 003 script emulate for this

//X 2 DEPLOY script. URL check.  SAME as above because same wallet.
//O 3 DEPLOY move to WEB3_Frontend_Digital_IDz? //URL? //Read/Write? //Vercel?
//O 4 INTERACT magicNum --goerli network="maticmum"

//O 4 WEB3_DIDZ_FULLSTACK with 005

//VERSION 2
  //O Metadata struct (version 2)
  //O do 005 dynamic (version 2)
  //O REPLACABLE, if the NFT if already minted? (version 2)
  //O value and withdraw
  //O Review on Tenderly?
  //O SELL SBT but has 0x on front.


  
