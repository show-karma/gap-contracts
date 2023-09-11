// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {ICommunityResolver} from "./ICommunityResolver.sol";
import {Attestation} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MilestoneApprovalResolver is
    SchemaResolver,
    Initializable,
    OwnableUpgradeable
{
    address private _owner;
    IEAS private eas;
    ICommunityResolver communityResolver;

    bytes32 private approvedHash = keccak256(abi.encodePacked("approved"));
    bytes32 private completedHash = keccak256(abi.encodePacked("completed"));
    bytes32 private rejectedHash = keccak256(abi.encodePacked("rejected"));

    constructor(IEAS easRef, ICommunityResolver resolver)
        SchemaResolver(easRef)
    {
        eas = easRef;
        communityResolver = resolver;
        _owner = msg.sender;
        _disableInitializers();
    }

    /**
     * Set the community resolver to check for admin privileges
     */
    function changeCommunityResolver(ICommunityResolver resolver) external {
        require(msg.sender == _owner, "Not owner.");
        communityResolver = resolver;
    }

    /**
     * Calls community resolver whitelist to check if address is
     * a community admin
     */
    function isCommunityAdmin(bytes32 communityUID, address addr)
        private
        view
        returns (bool)
    {
        return communityResolver.isAdmin(communityUID, addr);
    }

    /**
     * Decodes the milestone schema
     * @return typeHash "approved" | "rejected" | "completed"
     */
    function getMilestoneApprovalType(bytes memory milestoneData)
        public
        view
        returns (bytes32 typeHash)
    {
        (string memory type_, ) = abi.decode(milestoneData, (string, string));

        typeHash = keccak256(abi.encodePacked(type_));

        if (
            typeHash != approvedHash &&
            typeHash != completedHash &&
            typeHash != rejectedHash
        ) {
            revert("Invalid approval type.");
        }

        return (typeHash);
    }

    /**
     * Decodes the grant schema
     * @return the referred community UID
     */
    function getGrantCommunityUID(bytes memory grantData)
        public
        pure
        returns (bytes32)
    {
        return abi.decode(grantData, (bytes32));
    }

    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal view override returns (bool) {
        require(attestation.refUID != bytes32(0), "Invalid referred milestone");
        bytes32 typeHash = getMilestoneApprovalType(attestation.data);

        Attestation memory milestone = eas.getAttestation(attestation.refUID);
        require(milestone.uid != bytes32(0), "Invalid milestone reference");
        require(
            milestone.refUID != bytes32(0),
            "Invalid grant reference on milestone"
        );

        Attestation memory grant = eas.getAttestation(milestone.refUID);
        require(grant.uid != bytes32(0), "Invalid grant reference");
        bytes32 communityUID = getGrantCommunityUID(grant.data);

        bool communityAdmin = isCommunityAdmin(
            communityUID,
            attestation.attester
        );

        if (typeHash == completedHash) {
            require(
                milestone.attester == attestation.attester ||
                    milestone.recipient == attestation.attester ||
                    communityAdmin,
                "Not admin"
            );
        } else if (typeHash == rejectedHash || typeHash == approvedHash) {
            require(communityAdmin, "Not owner");
            Attestation memory community = eas.getAttestation(communityUID);
            require(community.uid != bytes32(0), "Invalid community reference");

        }
        return true;
    }

    function onRevoke(
        Attestation calldata, /*attestation*/
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }
}
