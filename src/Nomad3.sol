// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Nomad3
 * @dev Nomad3 is a contract for managing event NFTs.
 */
contract Nomad3 {
    //---------------------VARIABLE DECLARATIONS---------------------//

    /**
     * @dev Address of the contract that mints the event NFTs.
     */
    address public eventMinterContractAddress;

    /**
     * @dev I want to know in one glance how many years worth of event NFTs is being held by the address.
     * @dev e.g. with address 0x...09, I know that I have 2023 and 2024 NFT helds.
     * @dev This can be called internally or externally.
     */
    mapping(address => uint256[]) public addressToYears;

    /**
     * @dev I want to know in one glance how many events are in each years held by the address.
     * @dev e.g. with address 0x...09, I know that I have 2 events in 2023 and 1 event in 2024.
     * @dev This can be called internally or externally.
     */
    mapping(address => mapping(uint256 => uint256))
        public addressToYearToEventCount;

    /**
     * @dev A struct to specify the expected data for each event NFT powered by ERC6551.
     */
    struct Event {
        uint256 id; // The ID of the event.
        string name; // The name of the event.
        uint256 date; // The date of the event in UNIX timestamp.
        address contractAddress; // The address of the contract that minted the NFT.
        uint256 tokenId; // The ID of the NFT.
        address tbaAddress; // The address of the token bound account tied to the NFT.
    }

    /**
     * @dev I want to know what are the events held by the address in a specific year organized by index.
     */
    mapping(address => mapping(uint256 => mapping(uint256 => Event)))
        public addressToYearToEvents;

    //---------------------EVENTS---------------------//

    event EventMinterContractAddressUpdated(address indexed _address);

    event YearCreated(address indexed _address, uint256 indexed _year);

    event EventCreated(
        address indexed _address,
        uint256 indexed _year,
        string _name,
        uint256 _date,
        address _contractAddress,
        uint256 _tokenId,
        address _tbaAddress
    );

    event EventCountUpdated(
        address indexed _address,
        uint256 indexed _year,
        uint256 _eventCount
    );

    //---------------------ERRORS---------------------//
    error FutureYearError(uint256 _year);

    error YearExistsError(address _address, uint256 _year);

    error YearDoesNotExistError(address _address, uint256 _year);

    error EventExistsError(address _address, uint256 _year, uint256 _tokenId);

    error NotTokenBoundAccountError(address _address);

    //---------------------MODIFIERS---------------------//
    modifier yearNotInFuture(uint256 _year) {
        if (_year > getCurrentYear()) revert FutureYearError(_year);
        _;
    }

    modifier yearDoesNotExist(address _address, uint256 _year) {
        for (uint256 i = 0; i < addressToYears[_address].length; i++) {
            if (addressToYears[_address][i] == _year)
                revert YearExistsError(_address, _year);
        }
        _;
    }

    modifier eventDoesNotExist(
        address _address,
        uint256 _year,
        uint256 _tokenId
    ) {
        for (
            uint256 i = 0;
            i < addressToYearToEventCount[_address][_year];
            i++
        ) {
            if (addressToYearToEvents[_address][_year][i].tokenId == _tokenId)
                revert EventExistsError(_address, _year, _tokenId);
        }
        _;
    }

    modifier yearShouldExist(address _address, uint256 _year) {
        bool yearExists = false;
        for (uint256 i = 0; i < addressToYears[_address].length; i++) {
            if (addressToYears[_address][i] == _year) yearExists = true;
        }
        if (!yearExists) revert YearDoesNotExistError(_address, _year);
        _;
    }

    modifier onlyTBA(address _walletAddress) {
        if (msg.sender == _walletAddress)
            revert NotTokenBoundAccountError(_walletAddress);
        _;
    }

    //---------------------CONSTRUCTOR---------------------//
    constructor(address _eventMinterContractAddress) {
        eventMinterContractAddress = _eventMinterContractAddress;
    }

    //---------------------FUNCTIONS---------------------//

    /**
     * @dev I want to know how many years worth of event NFTs is being held by the address.
     */
    function getYears() public view returns (uint256[] memory) {
        return addressToYears[msg.sender];
    }

    /**
     * @dev I want to know how many events are in each years held by the address.
     */
    function getEventCount(uint256 _year) public view returns (uint256) {
        return addressToYearToEventCount[msg.sender][_year];
    }

    /**
     * @dev I want to know what are the events held by the address in a specific year.
     */
    function getEvents(uint256 _year) public view returns (Event[] memory) {
        Event[] memory events = new Event[](
            addressToYearToEventCount[msg.sender][_year]
        );
        for (
            uint256 i = 0;
            i < addressToYearToEventCount[msg.sender][_year];
            i++
        ) {
            events[i] = addressToYearToEvents[msg.sender][_year][i];
        }
        return events;
    }

    /**
     * @dev I want to know what is the current year in UNIX timestamp.
     */
    function getCurrentYear() public view returns (uint256) {
        uint256 secondsSinceEpoch = block.timestamp;
        uint256 averageSecondsPerYear = 365.25 * 24 * 60 * 60; // Average, accounting for leap years
        uint256 year = 1970 + secondsSinceEpoch / averageSecondsPerYear;

        return year;
    }

    /**
     * @dev I want to create a new year category for the address.
     * @dev A restriction is that this cannot be done for future years and a year that already exists.
     */
    function createYear(
        uint256 _year
    ) public yearNotInFuture(_year) yearDoesNotExist(msg.sender, _year) {
        addressToYears[msg.sender].push(_year);
        emit YearCreated(msg.sender, _year);
    }

    /**3
     * @dev I want to create a new event for the address in a specific year and update the event count.
     * @dev This is to be called by the newly deployed TBA. Append the call to this function alongside the TBA deployment using the SDK.
     * @dev Click on "Claim" button -> Claim the event-related NFT first, wait for tx to be mined -> use the SDK to deploy the TBA -> call this function.
     * @dev https://docs.tokenbound.org/sdk/methods#createaccount
     */
    function createEvent(
        address _walletAddress, // The address of the wallet that deployed the TBA.
        uint256 _year, // The year of the event.
        string memory _name, // The name of the event.
        uint256 _date, // The date of the event in UNIX timestamp.
        uint256 _tokenId, // The ID of the NFT.
        address tbaAddress // The address of the token bound account tied to the NFT.
    )
        public
        eventDoesNotExist(_walletAddress, _year, _tokenId)
        yearNotInFuture(_year)
        yearShouldExist(_walletAddress, _year)
        onlyTBA(_walletAddress)
    {
        addressToYearToEvents[_walletAddress][_year][
            addressToYearToEventCount[_walletAddress][_year]
        ] = Event(
            addressToYearToEventCount[_walletAddress][_year],
            _name,
            _date,
            eventMinterContractAddress,
            _tokenId,
            tbaAddress
        );
        addressToYearToEventCount[_walletAddress][_year]++;
        emit EventCreated(
            _walletAddress,
            _year,
            _name,
            _date,
            eventMinterContractAddress,
            _tokenId,
            tbaAddress
        );
        emit EventCountUpdated(
            _walletAddress,
            _year,
            addressToYearToEventCount[_walletAddress][_year]
        );
    }
}
