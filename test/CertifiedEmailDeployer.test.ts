contract("CertifiedEmailDeployer", async accounts => {
  const ArtifactDeployer = artifacts.require("CertifiedEmailDeployer");

  const v4 = require("uuid").v4;

  const as2networkAddress = accounts[0];

  let deployerContract;

  const certificateId = v4();

  beforeEach(async () => {
    deployerContract = await ArtifactDeployer.new({
      from: as2networkAddress,
    });
  });

  it("Check if it deploy correctly", async () => {
    assert.ok(deployerContract.address);
  });

  it("Call deployCertificate function as as2network role", async () => {
    const certificateContractAddress = await deployerContract.deployCertificate(
      certificateId,
      deployerContract.address,
      {
        from: as2networkAddress,
      },
    );

    assert.ok(certificateContractAddress);
  });
});
