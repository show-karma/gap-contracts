// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {ICommunityResolver} from "./ICommunityResolver.sol";
import {Attestation} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MilestoneStatusResolver is
    SchemaResolver,
    Initializable,
    OwnableUpgradeable
{
    address private _owner;
    ICommunityResolver communityResolver;

    bytes32 private approvedHash;
    bytes32 private completedHash;
    bytes32 private rejectedHash;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IEAS eas) SchemaResolver(eas) {
        _disableInitializers();
    }

    function initialize(ICommunityResolver resolver) public initializer {
        _owner = msg.sender;
        communityResolver = resolver;
        approvedHash = keccak256(abi.encodePacked("approved"));
        completedHash = keccak256(abi.encodePacked("completed"));
        rejectedHash = keccak256(abi.encodePacked("rejected"));
        __Ownable_init();
    }

    /**
     * Set the community resolver to check for admin privileges
     */
    function changeCommunityResolver(ICommunityResolver resolver) onlyOwner external {
        communityResolver = resolver;
    }

    function onAttest(
        Attestation calldata /*attestation*/,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }

    function onRevoke(
        Attestation calldata /*attestation*/,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }

    /**
     * Decodes the grant schema
     * @return the referred community UID
     */
    function getGrantCommunityUID(
        bytes memory grantData
    ) private pure returns (bytes32) {
        return abi.decode(grantData, (bytes32));
    }

    /**
     * Calls community resolver whitelist to check if address is
     * a community admin
     */
    function isCommunityAdmin(
        bytes32 communityUID,
        address addr
    ) private returns (bool) {
        return communityResolver.isAdmin(communityUID, addr);
    }
}
