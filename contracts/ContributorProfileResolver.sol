// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {Attestation} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ContributorProfileResolver is
    SchemaResolver,
    Initializable,
    OwnableUpgradeable
{
    address private _owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IEAS eas) SchemaResolver(eas) {
        _disableInitializers();
    }

    function initialize() public initializer {
        _owner = msg.sender;
        __Ownable_init();
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
