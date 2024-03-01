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
    IProjectResolver public _projectResolver;

    bytes32 public _grantSchemaUid;
    bytes32 public _projectSchemaUid;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IEAS eas) SchemaResolver(eas) {
        _disableInitializers();
    }

    function initialize() public initializer {
        _owner = msg.sender;
        __Ownable_init();
    }

    function setProjectResolver(
        IProjectResolver projectResolver
    ) public onlyOwner {
        _projectResolver = projectResolver;
    }

    function setGrantSchema(bytes32 grantSchemaUid) public onlyOwner {
        _grantSchemaUid = grantSchemaUid;
    }

    function setProjectSchema(bytes32 projectSchemaUid) public onlyOwner {
        _projectSchemaUid = projectSchemaUid;
    }

    function refIsProject(bytes32 refSchemaUid) public view returns (bool) {
        return (refSchemaUid == _projectSchemaUid);
    }

    function refIsGrant(bytes32 refSchemaUid) public view returns (bool) {
        return (refSchemaUid == _grantSchemaUid);
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
}
