pragma solidity <0.6.0;

/*
Gas to deploy: 2.623.165
*/

import "./Clause.sol";

contract TimeLogger is Clause("timelogger-clause-notifiers") {
    uint256 public constant SECONDS_PER_DAY = 86400;

    string public constant SOLIDITY_SOURCE = "solidity";
    string public constant EXTERNAL_SOURCE = "external";

    string public constant CLAUSE_EVENT_TYPE = "timelog.added";
    string public constant CREATION_EVENT_TYPE = "timelogger_clause.created";

    string public constant VALIDATED_NOTIFIERS_KEY = "validated-notifiers";

    struct TimeLog {
        uint256 timeStart;
        uint256 timeEnd;
        string source;
        bool valid;
    }

    struct Day {
        uint256[] timelogs;
        uint256 total;
        bool existence;
    }

    AS2networkUserInterface public ownerContract;

    bool public expired;

    uint256 public endDate;
    uint256 public startDate;
    uint256 public weeklyHours;
    uint256 public lastOpenDay = 0;

    int256 public duration;

    TimeLog[] public timeLog;

    mapping(uint256 => Day) private day;

    constructor(
        address managerContractAddress,
        address ownerContractAddress,
        address signatureContractAddress,
        string memory id,
        string memory document,
        uint256 start,
        uint256 end,
        uint256 weekHours,
        int256 contractDuration
    ) public {
        contractId = id;
        documentId = document;

        startDate = start;
        endDate = end;
        weeklyHours = weekHours;
        duration = contractDuration;

        expired = false;

        userContract = AS2networkUserInterface(managerContractAddress);
        ownerContract = AS2networkUserInterface(ownerContractAddress);
        signatureContract = NotifierInterface(signatureContractAddress);

        userContract.setAddressArrayAttribute(VALIDATED_NOTIFIERS_KEY, userContract.ownerAddress());
        userContract.setAddressArrayAttribute(VALIDATED_NOTIFIERS_KEY, ownerContract.ownerAddress());

        _notifySignature(CREATION_EVENT_TYPE);
    }

    modifier onlyManager() {
        require(msg.sender == address(userContract.ownerAddress()), "Only the manager account can perform this action");

        _;
    }

    modifier onlyOwner() {
        require(msg.sender == address(ownerContract.ownerAddress()), "Only the owner account can perform this action");

        _;
    }

    modifier notExpired() {
        require(expired == false, "This contract has expired");

        _;
    }

    //Externals
    function externalSourceLog(uint256 time) external onlyManager notExpired {
        _logTime(time, EXTERNAL_SOURCE);
    }

    function soliditySourceLog() external onlyOwner notExpired {
        _logTime(block.timestamp, SOLIDITY_SOURCE);
    }

    function expireContract() external onlyManager {
        expired = true;
    }

    function createTimeLog(
        uint256 thisDay,
        uint256 start,
        uint256 end
    ) external onlyManager {
        _setDay(thisDay);

        _createLog(thisDay, start, EXTERNAL_SOURCE);

        _closeLog(thisDay, end, EXTERNAL_SOURCE);
    }

    function editTimeLog(
        uint256 thisDay,
        uint256 logIndex,
        uint256 start,
        uint256 end,
        bool validity
    ) external onlyManager {
        require(end >= start, "Invalid time frame");

        uint256 index = day[thisDay].timelogs[logIndex];

        timeLog[index].timeStart = start;
        timeLog[index].timeEnd = end;
        timeLog[index].valid = validity;
        timeLog[index].source = EXTERNAL_SOURCE;

        _recalculateTotal(thisDay);
    }

    //Getters

    function getDayTime(uint256 thisDay) external view returns (uint256 total) {
        if (!day[thisDay].existence) return 0;

        return day[thisDay].total;
    }

    function getTotalLoggedTime(uint256 startDay, uint256 endDay) external view returns (uint256 total) {
        if (startDay > endDay) return 0;

        uint256 totalAmount = 0;

        for (uint256 i = startDay; i <= endDay; i++) {
            if (day[i].existence) totalAmount += day[i].total;
        }

        return totalAmount;
    }

    function getTimeLog(uint256 thisDay, uint256 index)
        external
        view
        returns (
            uint256 start,
            uint256 end,
            string memory source,
            bool valid,
            bool more
        )
    {
        if (!day[thisDay].existence || day[thisDay].timelogs.length <= index) {
            return (0, 0, "", false, false);
        }

        bool thereIsMore = false;

        if (index < day[thisDay].timelogs.length - 1) thereIsMore = true;

        return (
            timeLog[day[thisDay].timelogs[index]].timeStart,
            timeLog[day[thisDay].timelogs[index]].timeEnd,
            timeLog[day[thisDay].timelogs[index]].source,
            timeLog[day[thisDay].timelogs[index]].valid,
            thereIsMore
        );
    }

    //Internals

    function _logTime(uint256 time, string memory source) internal {
        uint256 today = time / SECONDS_PER_DAY;

        _setDay(today);

        if (lastOpenDay != 0) {
            if (today > lastOpenDay) {
                _completePendingDays(today, time, source);
            } else {
                _closeLog(today, time, source);
            }

            lastOpenDay = 0;

            return;
        }

        _createLog(today, time, source);

        lastOpenDay = today;

        _notify(CLAUSE_EVENT_TYPE);
    }

    function _createLog(
        uint256 thisDay,
        uint256 startTime,
        string memory source
    ) internal {
        timeLog.push(TimeLog(startTime, 0, source, true));

        day[thisDay].timelogs.push(timeLog.length - 1);
    }

    function _closeLog(
        uint256 thisDay,
        uint256 endTime,
        string memory source
    ) internal {
        uint256 index = day[thisDay].timelogs[day[thisDay].timelogs.length - 1];

        require(endTime >= timeLog[index].timeStart, "Invalid time frame");

        //Assumption: if source coming from input doesnt equal the one saved, prefer the last one
        if (keccak256(abi.encodePacked((timeLog[index].source))) != keccak256(abi.encodePacked((source))))
            timeLog[index].source = source;

        timeLog[index].timeEnd = endTime;

        day[thisDay].total += endTime - timeLog[index].timeStart;
    }

    function _completePendingDays(
        uint256 today,
        uint256 nowInSeconds,
        string memory source
    ) internal {
        uint256 lastMidnight = (lastOpenDay * SECONDS_PER_DAY) + SECONDS_PER_DAY;

        _closeLog(lastOpenDay, lastMidnight, source);

        _completeDaysInTheGap(today, lastOpenDay);

        uint256 todayMidnight = today * SECONDS_PER_DAY;

        _createLog(today, todayMidnight, source);

        _closeLog(today, nowInSeconds, source);
    }

    function _completeDaysInTheGap(uint256 today, uint256 lastDay) internal {
        //fulfill the days in the gap with 24h single log
        for (uint256 i = lastDay + 1; i < today; i++) {
            _setDay(i);

            uint256 startOfTheDay = i * SECONDS_PER_DAY;
            uint256 endOfTheDay = startOfTheDay + SECONDS_PER_DAY;

            _createLog(i, startOfTheDay, SOLIDITY_SOURCE);

            _closeLog(i, endOfTheDay, SOLIDITY_SOURCE);
        }
    }

    function _recalculateTotal(uint256 thisDay) internal {
        uint256 totalAmount;

        for (uint256 i = 0; i < day[thisDay].timelogs.length; i++) {
            totalAmount += (timeLog[day[thisDay].timelogs[i]].timeEnd - timeLog[day[thisDay].timelogs[i]].timeStart);
        }

        day[thisDay].total = totalAmount;
    }

    function _setDay(uint256 today) internal {
        if (day[today].timelogs.length == 0) {
            uint256[] memory tmpArray;

            day[today] = Day(tmpArray, 0, true);
        }
    }
}
