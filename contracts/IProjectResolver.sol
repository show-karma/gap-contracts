// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/ISchemaResolver.sol";

interface IProjectResolver is ISchemaResolver {
    function isAdmin(
        bytes32 projectId,
        address addr
    ) external view returns (bool);
    
    function isOwner(
        bytes32 projectId,
        address addr
    ) external view returns (bool);

    function transferProjectOwnership(bytes32 uid, address newOwner) external;

    function addAdmin(bytes32 uid, address newAdmin) external;

    function removeAdmin(bytes32 uid, address admin) external;
}
