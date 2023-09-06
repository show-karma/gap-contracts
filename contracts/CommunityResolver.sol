// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {Attestation} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CommunityResolver is SchemaResolver, Initializable, OwnableUpgradeable {
    mapping(address => uint8) private communityAdmins;
    // can add community admins
    mapping(address => uint8) private admins;

    address private _owner;

    constructor(IEAS eas) SchemaResolver(eas) {
        _owner = msg.sender;
      _disableInitializers();
    }

    function canAttest(address attester) public view returns (bool) {
        return communityAdmins[attester] == 1 || attester == _owner;
    }

    function enlist(address addr) public virtual {
        // Admin can attest and also add other admins
        require(admins[msg.sender] == 1, "Not admin");
        communityAdmins[addr] = 1;
    }

    function delist(address addr) public {
        // Admin can attest and also remove other admins
        require(admins[msg.sender] == 1, "Not admin");
        communityAdmins[addr] = 0;
    }

    /**
     * This is an bottom up event, called from the attest contract
     */
    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal view override returns (bool) {
        return canAttest(attestation.attester);
    }

    /**
     * This is an bottom up event, called from the attest contract
     */
    function onRevoke(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal view override returns (bool) {
        return canAttest(attestation.attester);
    }
}
