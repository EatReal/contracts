// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Nomad3
 * @dev Nomad3 is a contract for managing event NFTs.
 */
contract Nomad3 {
    //---------------------VARIABLE DECLARATIONS---------------------//

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
        string name; // The name of the event.
        uint256 date; // The date of the event in UNIX timestamp.
        address contractAddress; // The address of the contract that minted the NFT.
        uint256 tokenId; // The ID of the NFT.
        address tbaAddress; // The address of the token bound account tied to the NFT.
    }

    /**
     * @dev I want to know what are the events held by the address in a specific year.
     */
    mapping(address => mapping(uint256 => Event[]))
        public addressToYearToEvents;

    //---------------------EVENTS---------------------//

    //---------------------MODIFIERS---------------------//

    //---------------------FUNCTIONS---------------------//

    /**
     * @dev I want to know how many years worth of event NFTs is being held by the address.
     */
    function getYears(address _address) public view returns (uint256[] memory) {
        return addressToYears[_address];
    }

    /**
     * @dev I want to know how many events are in each years held by the address.
     */
    function getEventCount(
        address _address,
        uint256 _year
    ) public view returns (uint256) {
        return addressToYearToEventCount[_address][_year];
    }

    /**
     * @dev I want to know what are the events held by the address in a specific year.
     * TODO: Format this to return data in a way that is easy to read.
     */
    function getEvents(
        address _address,
        uint256 _year
    ) public view returns (Event[] memory) {
        for (uint256 i = 0; i < addressToYears[_address].length; i++) {
            if (addressToYears[_address][i] == _year) {
                return addressToYearToEvents[_address][_year];
            }
        }
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
    function createYear(address _address, uint256 _year) public {
        require(
            _year <= getCurrentYear(),
            "Cannot create a year in the future."
        );

        for (uint256 i = 0; i < addressToYears[_address].length; i++) {
            require(
                addressToYears[_address][i] != _year,
                "Year already exists."
            );
        }
        addressToYears[_address].push(_year);
    }

    /**
     * @dev I want to create a new event for the address in a specific year and update the event count.
     * @dev This is to be called by the newly deployed TBA. Append the call to this function alongside the TBA deployment using the SDK.
     * @dev Click on "Claim" button -> Claim the event-related NFT first, wait for tx to be mined -> use the SDK to deploy the TBA -> call this function.
     * @dev https://docs.tokenbound.org/sdk/methods#createaccount
     * @dev TODO: figure out how to check the poap on gnosis from viction
     */
    function createEvent(
        address _walletAddress, // The address of the wallet that deployed the TBA.
        uint256 _year, // The year of the event.
        string memory _name, // The name of the event.
        uint256 _date, // The date of the event in UNIX timestamp.
        address _contractAddress, // The address of the contract that minted the NFT. TODO: maintain same contract address for all events.
        uint256 _tokenId // The ID of the NFT.
    ) public {
        // TODO: prevent duplicate event entries
        addressToYearToEvents[_walletAddress][_year].push(
            Event({
                name: _name,
                date: _date,
                contractAddress: _contractAddress,
                tokenId: _tokenId,
                tbaAddress: msg.sender
            })
        );
        addressToYearToEventCount[_walletAddress][_year]++;
    }
}
