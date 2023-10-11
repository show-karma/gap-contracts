// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {IEAS, Attestation, AttestationRequest, AttestationRequestData, MultiAttestationRequest, MultiRevocationRequest} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

contract Gap is Initializable, OwnableUpgradeable, EIP712Upgradeable {
    IEAS public eas;
    mapping(address => uint256) public nonces;

    bytes32 public constant ATTEST_TYPEHASH =
        keccak256("Attest(string payloadHash,uint256 nonce,uint256 expiry)");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    struct AttestationRequestNode {
        bytes32 uid;
        MultiAttestationRequest multiRequest;
        uint256 refIdx;
    }

    event GapAttested(address indexed attester, bytes32 uid);

    function initialize(address easAddr) public initializer {
        eas = IEAS(easAddr);
        __EIP712_init("gap-attestation", "1");
        __Ownable_init();
    }

    function attest(
        AttestationRequest calldata request
    ) external payable returns (bytes32) {
        return _attest(request, msg.sender);
    }

    ///
    /// Performs a single attestation by signature
    ///
    function attestBySig(
        AttestationRequest calldata request,
        string memory payloadHash,
        address attester,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bytes32) {
        require(block.timestamp <= expiry, "Signature expired");

        address signer = _recoverSignerAddress(
            payloadHash,
            nonce,
            expiry,
            v,
            r,
            s
        );
        require(
            signer == attester,
            "Signer and attester addresses don't match."
        );
        require(nonce == nonces[signer]++, "Invalid nonce");
        return _attest(request, signer);
    }

    function multiSequentialAttest(
        AttestationRequestNode[] calldata requestNodes
    ) external payable {
        _multiSequentialAttest(requestNodes, msg.sender);
    }

    ///
    /// Performs multi attestations by signature
    ///
    function multiSequentialAttestBySig(
        AttestationRequestNode[] calldata requestNodes,
        string memory payloadHash,
        address attester,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= expiry, "Signature expired");

        address signer = _recoverSignerAddress(
            payloadHash,
            nonce,
            expiry,
            v,
            r,
            s
        );
        require(
            signer == attester,
            "Signer and attester addresses don't match."
        );
        require(nonce == nonces[signer]++, "Invalid nonce");
        _multiSequentialAttest(requestNodes, signer);
    }

    function multiRevoke(
        MultiRevocationRequest[] calldata multiRequests
    ) external payable {
        _multiRevoke(multiRequests, msg.sender);
    }

    ///
    /// Performs multi revoke by sig
    ///
    function multiRevokeBySig(
        MultiRevocationRequest[] calldata multiRequests,
        string memory payloadHash,
        address attester,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= expiry, "Signature expired");

        address signer = _recoverSignerAddress(
            payloadHash,
            nonce,
            expiry,
            v,
            r,
            s
        );

        require(
            signer == attester,
            "Signer and attester addresses don't match."
        );
        require(nonce == nonces[signer]++, "Invalid nonce");
        _multiRevoke(multiRequests, signer);
    }

    ///
    /// Performs a multi attest with relations between attestations and
    /// assess for attesation permissions based on the parent attestation.
    /// If refUID is set in any attestation it will be ignored.
    ///
    function _multiSequentialAttest(
        AttestationRequestNode[] calldata requestNodes,
        address attester
    ) private {
        bytes32[][] memory totalUids = new bytes32[][](requestNodes.length);

        for (uint256 i = 0; i < requestNodes.length; i++) {
            MultiAttestationRequest memory request = requestNodes[i]
                .multiRequest;
            // If first item reference an attestation, checks if sender
            // is owner or attester of that attestation.
            validateCanAttestToRefs(request.data, attester);
            // Updates the upcoming attestation reference uids.
            if (i > 0) {
                for (uint256 j = 0; j < request.data.length; j++) {
                    AttestationRequestData memory data = request.data[j];
                    // If a request already has a ref, should not change it.
                    if (data.refUID == bytes32(0)) {
                        data.refUID = totalUids[requestNodes[i].refIdx][0];
                        request.data[j] = data;
                    }
                }
            }

            MultiAttestationRequest[]
                memory requests = new MultiAttestationRequest[](1);
            requests[0] = request;
            totalUids[i] = eas.multiAttest(requests);

            for (uint256 j = 0; j < totalUids[i].length; j++) {
                emit GapAttested(attester, totalUids[i][j]);
            }
        }
    }

    ///
    /// Perform a single attestation
    ///
    function _attest(
        AttestationRequest calldata request,
        address attester
    ) private returns (bytes32) {
        AttestationRequestData[]
            memory requestData = new AttestationRequestData[](1);
        requestData[0] = request.data;
        validateCanAttestToRefs(requestData, attester);

        bytes32 uid = eas.attest(request);

        emit GapAttested(attester, uid);

        return uid;
    }

    ///
    /// Revokes multiple attestations
    ///
    function _multiRevoke(
        MultiRevocationRequest[] calldata multiRequests,
        address revoker
    ) private {
        // Checks if every revoke request belongs to the sender
        // The sender can be either the attester or the recipient.
        for (uint256 i = 0; i < multiRequests.length; i++) {
            MultiRevocationRequest memory request = multiRequests[i];
            for (uint256 j = 0; j < request.data.length; j++) {
                Attestation memory target = eas.getAttestation(
                    request.data[j].uid
                );

                require(
                    revoker == owner() ||
                        target.attester == revoker ||
                        target.recipient == revoker,
                    "GAP:Not owner."
                );
            }
        }
        eas.multiRevoke(multiRequests);
    }

    ///
    /// Verify if msg.sender owns the referenced attestation
    ///
    function validateCanAttestToRef(
        bytes32 uid,
        address attester
    ) private view {
        Attestation memory ref = eas.getAttestation(uid);
        require(
            attester == owner() ||
                ref.attester == msg.sender ||
                ref.recipient == msg.sender ||
                ref.attester == attester ||
                ref.recipient == attester,
            "GAP:Not owner."
        );
    }

    ///
    /// Verify if msg.sender owns the set of attestations
    ///
    function validateCanAttestToRefs(
        AttestationRequestData[] memory datas,
        address signer
    ) private view {
        for (uint256 j = 0; j < datas.length; j++) {
            if (datas[j].refUID != bytes32(0)) {
                validateCanAttestToRef(datas[j].refUID, signer);
            }
        }
    }

    function _recoverSignerAddress(
        string memory payloadHash,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (address signer) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ATTEST_TYPEHASH,
                    keccak256(bytes(payloadHash)),
                    nonce,
                    expiry
                )
            )
        );

        signer = ECDSAUpgradeable.recover(digest, v, r, s);

        return (signer);
    }
}
