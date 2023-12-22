// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./Nomad3.sol";

interface IERC6551Account {
    receive() external payable;

    function token()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId);

    function state() external view returns (uint256);

    function isValidSigner(
        address signer,
        bytes calldata context
    ) external view returns (bytes4 magicValue);
}

interface IERC6551Executable {
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable returns (bytes memory);
}

contract ERC6551Account is
    IERC165,
    IERC1271,
    IERC6551Account,
    IERC6551Executable
{
    uint256 public state;

    /**
     * @dev Struct to determine how the connection details are stored
     */
    struct Connection {
        string name;
        address walletAddress;
        string profilePicture;
    }

    /**
     * @dev Store all the connections in an array
     */
    Connection[] public connections;

    /**
     * @dev An error to detect if a connection already exists
     */
    error ConnectionAlreadyExists(address _walletAddress);

    /**
     * @dev An event to detect when a connection is created
     */
    event ConnectionCreated(
        string name,
        address walletAddress,
        string profilePicture
    );

    /**
     * @dev An array of IPFS hashes to store the event pictures
     */
    string[] public eventPictures;

    /**
     * @dev An error to detect if an event picture already exists
     */
    error EventPictureAlreadyExists(string _eventPicture);

    /**
     * @dev An event to detect when an event picture is created
     */
    event EventPictureUploaded(string eventPicture);

    receive() external payable {}

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable virtual returns (bytes memory result) {
        require(_isValidSigner(msg.sender), "Invalid signer");
        require(operation == 0, "Only call operations are supported");

        ++state;

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function isValidSigner(
        address signer,
        bytes calldata
    ) external view virtual returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view virtual returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return bytes4(0);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure virtual returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId;
    }

    function token() public view virtual returns (uint256, address, uint256) {
        bytes memory footer = new bytes(0x60);

        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    function owner() public view virtual returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function _isValidSigner(
        address signer
    ) internal view virtual returns (bool) {
        return signer == owner();
    }

    /**
     * @dev I want to get the full list of connections
     */
    function getConnections() public view returns (Connection[] memory) {
        return connections;
    }

    /**
     * @dev I want to create a new connection
     * @dev A constraint is that the wallet address must be unique
     */
    function createConnection(
        string memory _name,
        address _walletAddress,
        string memory _profilePicture
    ) public {
        require(_isValidSigner(msg.sender), "Invalid signer");

        ++state;

        // Check if the connection already exists
        for (uint256 i = 0; i < connections.length; i++) {
            if (connections[i].walletAddress == _walletAddress) {
                revert ConnectionAlreadyExists(_walletAddress);
            }
        }

        connections.push(
            Connection({
                name: _name,
                walletAddress: _walletAddress,
                profilePicture: _profilePicture
            })
        );

        emit ConnectionCreated(_name, _walletAddress, _profilePicture);
    }

    /**
     * @dev I want to get the full list of event pictures
     */
    function getEventPictures() public view returns (string[] memory) {
        return eventPictures;
    }

    /**
     * @dev I want to create a new event picture
     * @dev A constraint is that the event picture must be unique
     */
    function createEventPicture(string memory _eventPicture) public {
        require(_isValidSigner(msg.sender), "Invalid signer");

        ++state;

        // Check if the event picture already exists
        for (uint256 i = 0; i < eventPictures.length; i++) {
            if (
                keccak256(bytes(eventPictures[i])) ==
                keccak256(bytes(_eventPicture))
            ) {
                revert EventPictureAlreadyExists(_eventPicture);
            }
        }

        eventPictures.push(_eventPicture);

        emit EventPictureUploaded(_eventPicture);
    }

    /**
     * @dev Calls createEvent on a Nomad3 contract instance specified by the user.
     * @param _nomad3Address The address of the Nomad3 contract.
     * @param _year The year of the event.
     * @param _name The name of the event.
     * @param _date The date of the event.
     * @param _tokenId The ID of the NFT.
     */
    function callCreateEventOnNomad3(
        address _nomad3Address,
        uint256 _year,
        string memory _name,
        uint256 _date,
        uint256 _tokenId
    ) public {
        // Ensure that the caller has the right permissions
        require(_isValidSigner(msg.sender), "Invalid signer");

        // Increment the state
        ++state;

        // Create an instance of the INomad3 interface pointing to _nomad3Address
        Nomad3 nomad3 = Nomad3(_nomad3Address);

        // Call the createEvent function on the specified Nomad3 contract
        nomad3.createEvent(
            msg.sender,
            _year,
            _name,
            _date,
            _tokenId,
            address(this)
        );
    }
}
