// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {Attestation} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CommunityResolver is
    SchemaResolver,
    Initializable,
    OwnableUpgradeable
{
    mapping(bytes32 => mapping(address => uint8)) private communityAdmins;

    address private _owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IEAS eas) SchemaResolver(eas) {
        _disableInitializers();
    }

    function initialize() public initializer {
        _owner = msg.sender;
        __Ownable_init();
    }

    function isAdmin(
        bytes32 community,
        address addr
    ) public view returns (bool) {
        return msg.sender == _owner || communityAdmins[community][addr] == 1;
    }

    function canAttest(address attester) public view returns (bool) {
        return attester == _owner;
    }

    function enlist(bytes32 community, address addr) public virtual {
        require(isAdmin(community, msg.sender), "CommunityResolver:Not owner");
        communityAdmins[community][addr] = 1;
    }

    function delist(bytes32 community, address addr) public {
        require(isAdmin(community, msg.sender), "CommunityResolver:Not owner");
        communityAdmins[community][addr] = 0;
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
        Attestation calldata /*attestation*/,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }
}
