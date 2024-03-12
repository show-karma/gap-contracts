// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {Attestation} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ProjectResolver is SchemaResolver, Initializable, OwnableUpgradeable {
    mapping(bytes32 => address) public projectAdmin;

    address private _owner;

    mapping(bytes32 => address) public projectOwner;

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
        return
            (projectOwner[projectId] == address(0) &&
                _eas.getAttestation(projectId).recipient == addr) || projectOwner[projectId] == addr
                || addr == _owner;
    }

    function transferProjectOwnership(bytes32 uid, address newOwner) public {
        require(isAdmin(uid, msg.sender), "ProjectResolver:Not owner");
        projectOwner[uid] = newOwner;
        emit TransferOwnership(uid, newOwner);
    }

    /**
     * This is an bottom up event, called from the attest contract
     */
    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal override returns (bool) {
        projectOwner[attestation.uid] = attestation.recipient;
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
