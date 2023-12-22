// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EventNFT is ERC721 {
    using Strings for uint256;

    uint256 private counter;

    struct Event {
        string metadata;
        uint256 maxDrops;
        uint256 minted;
        mapping(address => bool) hasMinted;
        bool isRegistered;
    }

    uint256 private currentTokenId = 0;
    mapping(uint256 => Event) private events; // Event ID to Event mapping

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function registerEvent(string memory metadata, uint256 maxDrops) public {
        uint256 newEventId = ++counter;

        require(!events[newEventId].isRegistered, "Event already registered");

        Event storage newEvent = events[newEventId];
        newEvent.metadata = metadata;
        newEvent.maxDrops = maxDrops;
        newEvent.minted = 0;
        newEvent.isRegistered = true;
    }

    function mintNFT(uint256 eventId) public {
        Event storage event_ = events[eventId];
        require(event_.maxDrops > 0, "Event does not exist");
        require(
            event_.minted < event_.maxDrops,
            "All NFTs for this event have been minted"
        );
        require(
            !event_.hasMinted[msg.sender],
            "Address has already minted for this event"
        );

        event_.hasMinted[msg.sender] = true;
        event_.minted++;

        uint256 newTokenId = ++currentTokenId;
        _safeMint(msg.sender, newTokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    events[tokenId].metadata,
                    "/",
                    tokenId.toString()
                )
            );
    }
}
