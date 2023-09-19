// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {Attestation} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ReferrerResolver is SchemaResolver, Initializable, OwnableUpgradeable {
    address private _owner;
    IEAS private eas;

    constructor(IEAS easRef) SchemaResolver(easRef) {
        eas = easRef;
        _owner = msg.sender;
        _disableInitializers();
    }

    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal view override returns (bool) {
        if (attestation.refUID != bytes32(0)) {
            Attestation memory ref = eas.getAttestation(attestation.refUID);
            require(ref.uid != bytes32(0), "Referred attestation not valid.");
            require(
                ref.attester == attestation.attester ||
                    ref.recipient == attestation.attester ||
                    _owner == attestation.attester,
                "Not owner"
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
