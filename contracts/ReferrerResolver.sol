// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IProjectResolver} from "./IProjectResolver.sol";
import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {ISchemaRegistry, SchemaRecord} from "@ethereum-attestation-service/eas-contracts/contracts/ISchemaRegistry.sol";
import {Attestation} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ReferrerResolver is SchemaResolver, Initializable, OwnableUpgradeable {
    address private _owner;
    IProjectResolver private _projectResolver;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        IProjectResolver projectResolver,
        IEAS eas
    ) SchemaResolver(eas) {
        _projectResolver = projectResolver;
        _disableInitializers();
    }

    function initialize() public initializer {
        _owner = msg.sender;
        __Ownable_init();
    }

    function refIsProject(bytes32 refSchemaUid) public view returns (bool) {
        ISchemaRegistry registry = _eas.getSchemaRegistry();
        SchemaRecord memory schema = registry.getSchema(refSchemaUid);
        return address(schema.resolver) == address(_projectResolver);
    }

    function setProjectResolver(
        IProjectResolver projectResolver
    ) public onlyOwner {
        _projectResolver = projectResolver;
    }

    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal view override returns (bool) {
        if (attestation.refUID != bytes32(0)) {
            Attestation memory ref = _eas.getAttestation(attestation.refUID);
            require(ref.uid != bytes32(0), "Referred attestation not valid.");
            require(
                (refIsProject(ref.schema) &&
                    _projectResolver.isAdmin(ref.uid, attestation.recipient)) ||
                    ref.attester == attestation.attester ||
                    ref.recipient == attestation.recipient ||
                    _owner == attestation.attester,
                "ReferrerResolver:Not owner"
            );
        }
        return true;
    }

    function onRevoke(
        Attestation calldata /*attestation*/,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }
}
