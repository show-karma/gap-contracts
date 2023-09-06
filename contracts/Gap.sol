// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IEAS, Attestation, AttestationRequest, AttestationRequestData, MultiAttestationRequest, MultiRevocationRequest} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

contract Gap is Initializable, OwnableUpgradeable {
    IEAS public eas;

    struct AttestationRequestNode {
        bytes32 uid;
        MultiAttestationRequest multiRequest;
        uint256 refIdx;
    }

    function initialize(address easAddr) public initializer {
        eas = IEAS(easAddr);
        __Ownable_init();
    }

    /// 
    /// Verify if msg.sender owns the referenced attestation
    /// 
    function canAttestToRef(bytes32 uid) public view {
        Attestation memory ref = eas.getAttestation(uid);
        require(
            ref.attester == msg.sender || ref.recipient == msg.sender,
            /* || msg.sender == owner() */
            // ↑ Should owner be able to revoke any attestation?
            "Not owner."
        );
    }

    ///
    /// Verify if msg.sender owns the set of attestations
    ///
    function canAttestToRefs(AttestationRequestData[] memory datas)
        private
        view
    {
        for (uint256 j = 0; j < datas.length; j++) {
            if (datas[j].refUID != bytes32(0)) {
                canAttestToRef(datas[j].refUID);
            }
        }
    }

    /// 
    /// Revokes multiple attestations
    /// 
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests)
        external
        payable
    {
        // Checks if every revoke request belongs to the sender
        // The sender can be either the attester or the recipient.
        for (uint256 i = 0; i < multiRequests.length; i++) {
            MultiRevocationRequest memory chunk = multiRequests[i];
            for (uint256 j = 0; j < chunk.data.length; j++) {
                Attestation memory target = eas.getAttestation(
                    chunk.data[j].uid
                );

                require(
                    target.attester == msg.sender ||
                        target.recipient == msg.sender,
                    /* || msg.sender == owner()*/
                    // ↑ Should owner be able to revoke any attestation?
                    "Not owner."
                );
            }
        }
        eas.multiRevoke(multiRequests);
    }

    function attest(AttestationRequest calldata request)
        external
        payable
        returns (bytes32)
    {
        if (request.data.refUID != bytes32(0)) {
            canAttestToRef(request.data.refUID);
        }

        return eas.attest(request);
    }

    function multiSequentialAttest(
        AttestationRequestNode[] calldata requestNodes
    ) public {
        bytes32[][] memory totalUids = new bytes32[][](requestNodes.length);

        for (uint256 i = 0; i < requestNodes.length; i++) {
            MultiAttestationRequest memory request = requestNodes[i]
                .multiRequest;
            // If first item reference an attestation, checks if sender
            // is owner or attester of that attestation.
            canAttestToRefs(request.data);
            // Updates the upcoming attestation reference uids.
            if (i > 0) {
                for (uint256 j = 0; j < request.data.length; j++) {
                    AttestationRequestData memory data = request.data[j];
                    // If a request already has a ref, should not change it.
                    if (data.refUID == bytes32(0)) {
                        data.refUID = totalUids[requestNodes[i].refIdx][0];
                        request.data[j] = data;
                    } else {
                        // otherwise check if is owner of the referred attestation
                        canAttestToRef(data.refUID);
                    }
                }
            }

            MultiAttestationRequest[]
                memory requests = new MultiAttestationRequest[](1);
            requests[0] = request;
            totalUids[i] = eas.multiAttest(requests);
        }
    }
}
