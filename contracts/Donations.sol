pragma solidity ^0.8.19;

import {Attestation, AttestationRequest, AttestationRequestData} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IGAP {
    function attest(
        AttestationRequest calldata request
    ) external payable returns (bytes32);
}

contract Donations is Initializable, OwnableUpgradeable {
    address private _owner;
    IGAP public gap_contract;

    // Define an event
    event DonationMade(
        address indexed donor,
        address indexed donee,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Initialize function
    function initialize(address _gap_contract_address) public initializer {
        gap_contract = IGAP(_gap_contract_address);
        _owner = msg.sender;
        __Ownable_init();
    }

    // GAP contract address setter
    function setGapContract(address _gap_contract_address) public onlyOwner {
        gap_contract = IGAP(_gap_contract_address);
    }

    // Donate function: Donate to an address and call the attest function on GAP contract with the attestation object
    function donate(
        AttestationRequest calldata endorsementRequest,
        uint256 amountInWei
    ) external payable returns (bytes32) {
        // Check if the donee is a non zero address
        require(
            endorsementRequest.data.recipient != address(0),
            "Donations: Donee address is zero"
        );
        // Check if the amount is greater than 0
        require(amountInWei > 0, "Donations: Amount should be greater than 0");
        // Check if the sender has sent the correct amount
        require(msg.value == amountInWei, "Donations: Incorrect amount");

        // Recipient of the donation
        address donee = endorsementRequest.data.recipient;

        // Split the donation - 1% to the owner and 99% to the donee
        uint256 ownerAmount = (amountInWei * 1) / 100;
        uint256 doneeAmount = amountInWei - ownerAmount;

        // Transfer the amount to the donee
        payable(donee).transfer(doneeAmount);

        // Transfer the amount to the owner
        payable(_owner).transfer(ownerAmount);

        // Emit the DonationMade event
        emit DonationMade(msg.sender, donee, amountInWei);

        // Finally make an endorsement attestation to the recipient
        // Return the attestation uid
        return gap_contract.attest(endorsementRequest);
    }
}
