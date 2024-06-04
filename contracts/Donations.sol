// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Attestation, AttestationRequest, AttestationRequestData} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGAP {
    function attest(
        AttestationRequest calldata request
    ) external payable returns (bytes32);
}

contract Donations is Ownable {
    address public _owner;
    IGAP public gap_contract;
    // Platform fee percentage in basis points
    uint256 public platformFeeInBasis;

    event DonationMade(
        address indexed donor,
        address indexed donee,
        uint256 amount
    );
    event CommissionEarned(address indexed owner, uint256 amount);
    event PlatformFeeSet(uint256 platformFeeInBasis);

    constructor(address _gap_contract_address, uint256 _platformFeeInBasis) {
        gap_contract = IGAP(_gap_contract_address);
        platformFeeInBasis = _platformFeeInBasis;
        _owner = msg.sender;
        emit PlatformFeeSet(_platformFeeInBasis);
    }

    // GAP contract address setter
    function setGapContract(address _gap_contract_address) public onlyOwner {
        gap_contract = IGAP(_gap_contract_address);
    }

    // Platform fee setter
    function setPlatformFeeInBasis(
        uint256 _platformFeeInBasis
    ) public onlyOwner {
        platformFeeInBasis = _platformFeeInBasis;
        emit PlatformFeeSet(_platformFeeInBasis);
    }

    // Donate function: Donate to an address and call the attest function on GAP contract with the attestation object
    function donate(
        AttestationRequest calldata endorsementRequest,
        uint256 amount
    ) external payable returns (bytes32) {
        // Check if the donee is a non zero address
        require(
            endorsementRequest.data.recipient != address(0),
            "Donations: Donee address is zero"
        );
        // Check if the amount is greater than 0
        require(amount > 0, "Donations: Amount should be greater than 0");
        // Check if the sender has sent the correct amount
        require(msg.value == amount, "Donations: Incorrect amount");

        // Recipient of the donation
        address donee = endorsementRequest.data.recipient;

        // Split the donation according to the platformFeeInBasis
        uint256 commission = (amount * platformFeeInBasis) / 10000;
        uint256 doneeAmount = amount - commission;

        // Transfer the amount to the donee
        payable(donee).transfer(doneeAmount);

        // Transfer the amount to the owner
        payable(_owner).transfer(commission);

        // Emit events
        emit DonationMade(msg.sender, donee, amount);
        emit CommissionEarned(_owner, commission);

        // Finally make an endorsement attestation to the recipient
        // Return the attestation uid
        return gap_contract.attest(endorsementRequest);
    }
}
