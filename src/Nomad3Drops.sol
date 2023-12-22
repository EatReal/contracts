// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IERC6551Registry.sol";

contract Nomad3Drops is ERC721 {
    using Strings for uint256;

    struct Event {
        string metadata;
        uint256 maxDrops;
        uint256 minted;
        mapping(address => bool) hasMinted;
        bool isRegistered;
    }

    address public erc6551RegistryAddress;
    address public erc6551ImplementationAddress;

    uint256 private currentEventId = 0;
    uint256 private currentTokenId = 0;

    mapping(uint256 => uint256) private tokenToEvent; // Token ID to Event ID mapping
    mapping(uint256 => Event) private events; // Event ID to Event mapping
    mapping(bytes32 => bool) private metadataHashes; // Metadata hash to bool mapping
    mapping(address => uint256[]) private organizerToEvents; // Organizer address to Event IDs mapping

    error EventAlreadyRegistered(uint256 eventId);
    error EventDoesNotExist(uint256 eventId);
    error MaxNFTsMinted(uint256 eventId);
    error AddressHasAlreadyMinted(uint256 eventId, address address_);
    error MetadataIsNotUnique(string metadata);
    error TokenDoesNotExist(uint256 tokenId);

    event EventCreated(uint256 eventId, string metadata, uint256 maxDrops);
    event NFTMinted(
        uint256 tokenId,
        uint256 eventId,
        address mintedBy,
        address tbaAddress
    );

    constructor(
        string memory name,
        string memory symbol,
        address erc6551RegistryAddress_,
        address erc6551ImplementationAddress_
    ) ERC721(name, symbol) {
        erc6551RegistryAddress = erc6551RegistryAddress_;
        erc6551ImplementationAddress = erc6551ImplementationAddress_;
    }

    function registerEvent(string memory metadata, uint256 maxDrops) public {
        bytes32 metadataHash = keccak256(abi.encodePacked(metadata));

        if (metadataHashes[metadataHash]) {
            revert MetadataIsNotUnique(metadata);
        }

        uint256 newEventId = ++currentEventId;

        Event storage newEvent = events[newEventId];
        newEvent.metadata = metadata;
        newEvent.maxDrops = maxDrops;
        newEvent.minted = 0;
        newEvent.isRegistered = true;

        metadataHashes[metadataHash] = true; // Mark this metadata as used

        // Link the new event ID to the organizer's address
        organizerToEvents[msg.sender].push(newEventId);

        emit EventCreated(newEventId, metadata, maxDrops);
    }

    function mintNFT(uint256 eventId) public returns (address payable) {
        Event storage event_ = events[eventId];

        if (event_.minted >= event_.maxDrops) {
            revert MaxNFTsMinted(eventId);
        }
        if (event_.hasMinted[msg.sender]) {
            revert AddressHasAlreadyMinted(eventId, msg.sender);
        }

        event_.hasMinted[msg.sender] = true;
        event_.minted++;

        uint256 newTokenId = ++currentTokenId;
        tokenToEvent[newTokenId] = eventId; // Link the new token ID to the event ID
        _safeMint(msg.sender, newTokenId);

        // Create an instance of the INomad3 interface pointing to _nomad3Address
        IERC6551Registry registry = IERC6551Registry(erc6551RegistryAddress);

        // Call the createAccount function on the specified Nomad3 contract
        address tbaAddress = registry.createAccount(
            erc6551ImplementationAddress,
            keccak256(abi.encodePacked(newTokenId)),
            block.chainid,
            address(this),
            newTokenId
        );

        emit NFTMinted(newTokenId, eventId, msg.sender, tbaAddress);

        return payable(tbaAddress);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (tokenToEvent[tokenId] == 0) {
            revert TokenDoesNotExist(tokenId);
        }

        uint256 eventId = tokenToEvent[tokenId];

        return
            string(
                abi.encodePacked(
                    events[eventId].metadata,
                    "/",
                    tokenId.toString()
                )
            );
    }

    function updateERC6551RegistryAddress(
        address erc6551RegistryAddress_
    ) public {
        erc6551RegistryAddress = erc6551RegistryAddress_;
    }

    function updateERC6551ImplementationAddress(
        address erc6551ImplementationAddress_
    ) public {
        erc6551ImplementationAddress = erc6551ImplementationAddress_;
    }

    function getEventIds() public view returns (uint256[] memory) {
        return organizerToEvents[msg.sender];
    }
}
