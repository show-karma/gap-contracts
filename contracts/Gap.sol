// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IEAS, AttestationRequest, AttestationRequestData, MultiAttestationRequest} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

contract Gap is Initializable, OwnableUpgradeable {
    IEAS public eas;

    struct AttestationRequestNode {
        bytes32 uid;
        MultiAttestationRequest multiRequest;
        uint refIdx;
    }

    function initialize(address easAddr) public initializer {
        eas = IEAS(easAddr);
        __Ownable_init();
    }

    function multiSequentialAttest(AttestationRequestNode[] calldata requestNodes) public {
        bytes32[][] memory totalUids = new bytes32[][](requestNodes.length);
        for(uint256 i = 0; i < requestNodes.length; i++) {
            MultiAttestationRequest memory request = requestNodes[i].multiRequest;
            if (i > 0) {
                for(uint256 j = 0; j < request.data.length; j++) {
                    AttestationRequestData memory data = request.data[j];
                    data.refUID = totalUids[requestNodes[i].refIdx][0];
                    request.data[j] = data;
                }
            }
            MultiAttestationRequest[] memory requests = new MultiAttestationRequest[](1);
            requests[0] = request;
            totalUids[i] = eas.multiAttest(requests);
        }
    }
}
