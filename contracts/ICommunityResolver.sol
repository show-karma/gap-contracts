// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/ISchemaResolver.sol";

interface ICommunityResolver is ISchemaResolver {
    isAdmin(bytes32 communityUID, address addr);
}