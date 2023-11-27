// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {Attestation} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ProjectResolver is SchemaResolver, Initializable, OwnableUpgradeable {
    mapping(bytes32 => address) private projectAdmin;

    address private _owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IEAS eas) SchemaResolver(eas) {
        _disableInitializers();
    }

    event TransferOwnership(bytes32 uid, address newOwner);

    function initialize() public initializer {
        _owner = msg.sender;
        __Ownable_init();
    }

    function isAdmin(
        bytes32 projectId,
        address addr
    ) public view returns (bool) {
        Attestation memory project = _eas.getAttestation(projectId);
        return
            (projectAdmin[projectId] == address(0) &&
                project.recipient == addr) || projectAdmin[projectId] == addr;
    }

    function transferProjectOwnership(bytes32 uid, address newOwner) public {
        require(isAdmin(uid, msg.sender), "ProjectResolver:Not owner");
        projectAdmin[uid] = newOwner;
        emit TransferOwnership(uid, newOwner);
    }

    /**
     * This is an bottom up event, called from the attest contract
     */
    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal override returns (bool) {
        projectAdmin[attestation.uid] = attestation.attester;
        return true;
    }

    /**
     * This is an bottom up event, called from the attest contract
     */
    function onRevoke(
        Attestation calldata /*attestation*/,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }
}
