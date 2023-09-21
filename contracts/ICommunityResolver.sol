// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/ISchemaResolver.sol";

interface ICommunityResolver is ISchemaResolver {
    function isAdmin(bytes32 communityUID, address addr) external returns (bool);
}
