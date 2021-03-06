contract("UserEvents", async accounts => {
  const truffleAssert = require("truffle-assertions");
  const v4 = require("uuid").v4;

  const ArtifactUser = artifacts.require("AS2networkUser");
  const ArtifactUserEvents = artifacts.require("UserEvents");
  const ArtifactSignature = artifacts.require("Signature");
  const ArtifactSignatureDeployer = artifacts.require("SignatureDeployer");
  const ArtifactCertifiedFile = artifacts.require("CertifiedFile");
  const ArtifactCertifiedEmail = artifacts.require("CertifiedEmail");
  const ArtifactCertifiedEmailDeployer = artifacts.require("CertifiedEmailDeployer");
  const ArtifactCertificate = artifacts.require("Certificate");
  const ArtifactDocument = artifacts.require("Document");
  const ArtifactEvent = artifacts.require("Event");
  const ArtifactTimeLogger = artifacts.require("TimeLogger");
  const ArtifactPayment = artifacts.require("Payment");

  const SIGNATURE_NOTIFIERS_KEY = "signature-notifiers";
  const DOCUMENT_NOTIFIERS_KEY = "document-notifiers";
  const FILE_NOTIFIERS_KEY = "file-notifiers";
  const EVENT_NOTIFIERS_KEY = "event-notifiers";
  const CERTIFIED_EMAIL_NOTIFIERS_KEY = "certified-email-notifiers";
  const CERTIFICATE_NOTIFIERS_KEY = "certificate-notifiers";
  const CERTIFIED_FILE_NOTIFIERS_KEY = "certified-file-notifiers";
  const TIMELOGGER_CLAUSE_NOTIFIERS_KEY = "timelogger-clause-notifiers";

  const ownerAddress = accounts[0];
  const as2networkUser = accounts[1];
  const managerAddress = accounts[2];
  const invalidAddress = accounts[3];

  const signatureId = v4();
  const signatureType = "advanced";
  const documentId = v4();
  const documentCreatedAt = Date.now();
  const documentSignedAt = Date.now();
  const documentDeclineReason = "decline reason";
  const documentCancelReason = "cancel reason";

  const eventId = v4();
  const eventType = "document_opened";
  const eventUserAgent = "user agent";
  const eventCreatedAt = Date.now();

  const fileId = v4();
  const fileSize = 123423;
  const fileName = "File.name";
  const fileHash = "asdf";
  const signedFileHash = "fdsa";
  const fileCreatedAt = Date.now();

  const certifiedEmailId = v4();
  const certifiedEmailSubject = "subject";
  const certifiedEmailBody = "body";
  const certifiedEmailDelivery = "full";
  const certifiedEmailCreatedAt = Date.now();

  const paymentContractId = v4();

  const timeLoggerContractId = v4();
  const startDate = Date.now();
  const endDate = Date.now() + 1000;
  const weekHours = 40;
  const contractDuration = 365;

  const certificateId = v4();
  const certificateCreatedAt = Date.now();

  const documentSignedEventId = "id_document_signed";
  const documentDeclinedEventId = "id_document_declined";
  const documentCanceledEventId = "id_document_canceled";
  const signedFileHashEventId = "id_file_signed_hash";

  const paymentContractStart = Date.now();
  const paymentContractEnd = Date.now() + 2000;
  const paymentContractPeriod = 1;
  const receiverId = v4();
  const referenceId = v4();
  const paymentCheckId = v4();
  const paymentCheckStatus = 2;
  const paymentCheckCheckedAt = Date.now();
  const paymentCheckCreatedAt = Date.now();

  let userEventsContract;
  let userContract;
  let managerContract;
  let signatureContract;
  let certifiedFileContract;
  let timeLoggerContract;
  let signatureDeployerContract;
  let certifiedEmailDeployerContract;
  let certifiedEmailContract;
  let paymentContract;

  beforeEach(async () => {
    userContract = await ArtifactUser.new(ownerAddress, {
      from: as2networkUser,
    });

    userEventsContract = await ArtifactUserEvents.new(userContract.address, {
      from: as2networkUser,
    });

    signatureDeployerContract = await ArtifactSignatureDeployer.new({ from: as2networkUser });
    certifiedEmailDeployerContract = await ArtifactCertifiedEmailDeployer.new({ from: as2networkUser });

    signatureContract = await ArtifactSignature.new(
      signatureId,
      signatureDeployerContract.address,
      Date.now(),
      ownerAddress,
      userContract.address,
      {
        from: as2networkUser,
      },
    );

    certifiedFileContract = await ArtifactCertifiedFile.new(
      ownerAddress,
      userContract.address,
      fileId,
      fileHash,
      fileCreatedAt,
      fileSize,
      {
        from: as2networkUser,
      },
    );

    certifiedEmailContract = await ArtifactCertifiedEmail.new(
      certifiedEmailId,
      certifiedEmailSubject,
      certifiedEmailBody,
      certifiedEmailDelivery,
      certifiedEmailCreatedAt,
      certifiedEmailDeployerContract.address,
      ownerAddress,
      userContract.address,
      {
        from: as2networkUser,
      },
    );

    managerContract = await ArtifactUser.new(managerAddress);

    timeLoggerContract = await ArtifactTimeLogger.new(
      userContract.address,
      managerContract.address,
      signatureContract.address,
      timeLoggerContractId,
      documentId,
      startDate,
      endDate,
      weekHours,
      contractDuration,
      {
        from: as2networkUser,
      },
    );

    paymentContract = await ArtifactPayment.new(userContract.address, signatureContract.address, paymentContractId, {
      from: as2networkUser,
    });
  });

  it("Check if it deploy correctly", async done => {
    assert.ok(userEventsContract);
    done();
  });

  it("Check if the deploy of the user events adds on the user", async () => {
    const signatureNotifierAddress = await userContract.getAddressArrayAttribute(SIGNATURE_NOTIFIERS_KEY, 0);
    const documentNotifierAddress = await userContract.getAddressArrayAttribute(DOCUMENT_NOTIFIERS_KEY, 0);
    const fileNotifierAddress = await userContract.getAddressArrayAttribute(FILE_NOTIFIERS_KEY, 0);
    const eventNotifierAddress = await userContract.getAddressArrayAttribute(EVENT_NOTIFIERS_KEY, 0);
    const certifiedEmailNotifierAddress = await userContract.getAddressArrayAttribute(CERTIFIED_EMAIL_NOTIFIERS_KEY, 0);
    const certificateNotifierAddress = await userContract.getAddressArrayAttribute(CERTIFICATE_NOTIFIERS_KEY, 0);
    const certifiedFileNotifierAddress = await userContract.getAddressArrayAttribute(CERTIFIED_FILE_NOTIFIERS_KEY, 0);

    assert.equal(signatureNotifierAddress, userEventsContract.address);
    assert.equal(documentNotifierAddress, userEventsContract.address);
    assert.equal(fileNotifierAddress, userEventsContract.address);
    assert.equal(eventNotifierAddress, userEventsContract.address);
    assert.equal(certifiedEmailNotifierAddress, userEventsContract.address);
    assert.equal(certificateNotifierAddress, userEventsContract.address);
    assert.equal(certifiedFileNotifierAddress, userEventsContract.address);
  });

  it("Deploy signature and expect to be notified", async () => {
    await signatureContract.notifyCreation({
      from: as2networkUser,
    });
    const events = await userEventsContract.getPastEvents("SignatureCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    assert.equal(events.length, 1);
    assert.equal(events[0].returnValues[0], signatureContract.address);
  });

  it("Deploy signature with document and file and expect to be notified", async () => {
    await signatureContract.notifyCreation({
      from: as2networkUser,
    });

    await signatureContract.createDocument(documentId, signatureType, documentCreatedAt, {
      from: as2networkUser,
    });

    await signatureContract.createFile(documentId, fileId, fileName, fileHash, fileCreatedAt, fileSize, {
      from: as2networkUser,
    });

    await signatureContract.createEvent(documentId, eventId, eventType, eventUserAgent, eventCreatedAt, {
      from: as2networkUser,
    });

    const signatureEvents = await userEventsContract.getPastEvents("SignatureCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    const documentEvents = await userEventsContract.getPastEvents("DocumentCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    const fileEvents = await userEventsContract.getPastEvents("FileCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    const eventEvents = await userEventsContract.getPastEvents("EventCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    const documentAddress = await signatureContract.getDocumentByIndex(0);
    const fileAddress = await signatureContract.getFile(documentId);
    const eventAddress = await signatureContract.getEvent(documentId, eventId);

    assert.equal(signatureEvents.length, 1);
    assert.equal(signatureEvents[0].returnValues[0], signatureContract.address);

    assert.equal(documentEvents.length, 1);
    assert.equal(documentEvents[0].returnValues[0], documentAddress);

    assert.equal(eventEvents.length, 1);
    assert.equal(eventEvents[0].returnValues[0], eventAddress);

    assert.equal(fileEvents.length, 1);
    assert.equal(fileEvents[0].returnValues[0], fileAddress);
  });

  it("Deploy certified email with certificate and file and expect to be notified", async () => {
    await certifiedEmailContract.notifyCreation({
      from: as2networkUser,
    });

    await certifiedEmailContract.createCertificate(certificateId, certificateCreatedAt, ownerAddress, {
      from: as2networkUser,
    });

    await certifiedEmailContract.createFile(certificateId, fileHash, fileId, fileName, fileCreatedAt, fileSize, {
      from: as2networkUser,
    });

    await certifiedEmailContract.createEvent(certificateId, eventId, eventType, eventUserAgent, eventCreatedAt, {
      from: as2networkUser,
    });

    const signatureEvents = await userEventsContract.getPastEvents("CertifiedEmailCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    const documentEvents = await userEventsContract.getPastEvents("CertificateCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    const fileEvents = await userEventsContract.getPastEvents("FileCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    const eventEvents = await userEventsContract.getPastEvents("EventCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    const certificateAddress = await certifiedEmailContract.getCertificateByIndex(0);
    const fileAddress = await certifiedEmailContract.getFile(certificateId);
    const eventAddress = await certifiedEmailContract.getEvent(certificateId, eventId);

    assert.equal(signatureEvents.length, 1);
    assert.equal(signatureEvents[0].returnValues[0], certifiedEmailContract.address);

    assert.equal(documentEvents.length, 1);
    assert.equal(documentEvents[0].returnValues[0], certificateAddress);

    assert.equal(eventEvents.length, 1);
    assert.equal(eventEvents[0].returnValues[0], eventAddress);

    assert.equal(fileEvents.length, 1);
    assert.equal(fileEvents[0].returnValues[0], fileAddress);
  });

  it("Deploy certified file and expect to be notified", async () => {
    await certifiedFileContract.notifyEvent({
      from: as2networkUser,
    });

    const events = await userEventsContract.getPastEvents("CertifiedFileCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    assert.equal(events.length, 1);
    assert.equal(events[0].returnValues[0], certifiedFileContract.address);
  });

  it("log a time and expect to be notified", async () => {
    await timeLoggerContract.soliditySourceLog({ from: managerAddress });

    const events = await userEventsContract.getPastEvents("TimeLogAdded", {
      fromBlock: 0,
      toBlock: "latest",
    });

    assert.equal(events.length, 1);
    assert.equal(events[0].returnValues[0], timeLoggerContract.address);
  });

  it("init payment and add a check, expect to be notified", async () => {
    await paymentContract.init(
      signatureId,
      documentId,
      paymentContractStart,
      paymentContractEnd,
      paymentContractPeriod,
      {
        from: as2networkUser,
      },
    );

    await paymentContract.addPaymentCheck(
      receiverId,
      referenceId,
      paymentCheckId,
      paymentCheckStatus,
      paymentCheckCheckedAt,
      paymentCheckCreatedAt,
      {
        from: as2networkUser,
      },
    );

    const events = await userEventsContract.getPastEvents("PaymentCheckAdded", {
      fromBlock: 0,
      toBlock: "latest",
    });

    assert.equal(events.length, 1);
    assert.equal(events[0].returnValues[0], paymentContract.address);
  });

  it("sign a document, expect to be notified", async () => {
    await signatureContract.notifyCreation({
      from: as2networkUser,
    });

    await signatureContract.createDocument(documentId, signatureType, documentCreatedAt, {
      from: as2networkUser,
    });

    await signatureContract.setDocumentOwner(documentId, as2networkUser, {
      from: as2networkUser,
    });

    const documentAddress = await signatureContract.getDocumentByIndex(0);

    const documentContract = await ArtifactDocument.at(documentAddress);

    await documentContract.sign(documentSignedAt, {
      from: as2networkUser,
    });

    const eventAddress = await documentContract.getEvent(documentSignedEventId);

    const eventContract = await ArtifactEvent.at(eventAddress);

    const events = await userEventsContract.getPastEvents("EventCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    assert.equal(events.length, 1);
    assert.equal(events[0].returnValues[0], eventContract.address);
  });

  it("decline a document, expect to be notified", async () => {
    await signatureContract.notifyCreation({
      from: as2networkUser,
    });

    await signatureContract.createDocument(documentId, signatureType, documentCreatedAt, {
      from: as2networkUser,
    });

    await signatureContract.setDocumentOwner(documentId, as2networkUser, {
      from: as2networkUser,
    });

    const documentAddress = await signatureContract.getDocumentByIndex(0);

    const documentContract = await ArtifactDocument.at(documentAddress);

    await documentContract.decline(documentDeclineReason, {
      from: as2networkUser,
    });

    const eventAddress = await documentContract.getEvent(documentDeclinedEventId);

    const eventContract = await ArtifactEvent.at(eventAddress);

    const events = await userEventsContract.getPastEvents("EventCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    assert.equal(events.length, 1);
    assert.equal(events[0].returnValues[0], eventContract.address);
  });

  it("cancel a document, expect to be notified", async () => {
    await signatureContract.notifyCreation({
      from: as2networkUser,
    });

    await signatureContract.createDocument(documentId, signatureType, documentCreatedAt, {
      from: as2networkUser,
    });

    await signatureContract.setDocumentOwner(documentId, as2networkUser, {
      from: as2networkUser,
    });

    const documentAddress = await signatureContract.getDocumentByIndex(0);

    const documentContract = await ArtifactDocument.at(documentAddress);

    await signatureContract.cancelDocument(documentId, documentCancelReason, {
      from: ownerAddress,
    });

    const eventAddress = await documentContract.getEvent(documentCanceledEventId);

    const eventContract = await ArtifactEvent.at(eventAddress);

    const events = await userEventsContract.getPastEvents("EventCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    assert.equal(events.length, 1);
    assert.equal(events[0].returnValues[0], eventContract.address);
  });

  it("set signed file hash, expect to be notified", async () => {
    await signatureContract.notifyCreation({
      from: as2networkUser,
    });

    await signatureContract.createDocument(documentId, signatureType, documentCreatedAt, {
      from: as2networkUser,
    });

    await signatureContract.setDocumentOwner(documentId, as2networkUser, {
      from: as2networkUser,
    });

    const documentAddress = await signatureContract.getDocumentByIndex(0);

    const documentContract = await ArtifactDocument.at(documentAddress);

    await signatureContract.setSignedFileHash(documentId, signedFileHash, {
      from: as2networkUser,
    });

    const eventAddress = await documentContract.getEvent(signedFileHashEventId);

    const eventContract = await ArtifactEvent.at(eventAddress);

    const events = await userEventsContract.getPastEvents("EventCreated", {
      fromBlock: 0,
      toBlock: "latest",
    });

    assert.equal(events.length, 1);
    assert.equal(events[0].returnValues[0], eventContract.address);
  });
});
