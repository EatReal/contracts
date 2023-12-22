// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INomad3 {
    /**
     * @dev Function signature of the createEvent function in the Nomad3 contract.
     */
    function createEvent(
        address _walletAddress,
        uint256 _year,
        string memory _name,
        uint256 _date,
        address _contractAddress,
        uint256 _tokenId
    ) external; // Use `external` if the original function is external, otherwise use `public`
}
