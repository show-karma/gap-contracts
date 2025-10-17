// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockPermit2 {
    struct TokenPermissions {
        address token;
        uint256 amount;
    }

    struct PermitTransferFrom {
        TokenPermissions permitted;
        address spender;
        uint256 nonce;
        uint256 deadline;
    }

    struct PermitBatchTransferFrom {
        TokenPermissions[] permitted;
        address spender;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    error DeadlineExpired();
    error AmountExceeded();
    error TransferFailed();
    error LengthMismatch();
    error InvalidSpender();

    event MockSignatureTransfer(
        address indexed owner,
        address indexed token,
        address indexed recipient,
        uint256 amount
    );

    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata /*signature*/
    ) external {
        if (block.timestamp > permit.deadline) revert DeadlineExpired();
        if (permit.spender != msg.sender) revert InvalidSpender();
        if (transferDetails.requestedAmount > permit.permitted.amount) revert AmountExceeded();

        _transfer(permit.permitted.token, owner, transferDetails.to, transferDetails.requestedAmount);
    }

    function permitTransferFrom(
        PermitBatchTransferFrom calldata permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata /*signature*/
    ) external {
        if (block.timestamp > permit.deadline) revert DeadlineExpired();
        uint256 length = permit.permitted.length;
        if (length != transferDetails.length) revert LengthMismatch();
        if (permit.spender != msg.sender) revert InvalidSpender();

        for (uint256 i = 0; i < length; i++) {
            if (transferDetails[i].requestedAmount > permit.permitted[i].amount) revert AmountExceeded();
            _transfer(
                permit.permitted[i].token,
                owner,
                transferDetails[i].to,
                transferDetails[i].requestedAmount
            );
        }
    }

    function _transfer(
        address token,
        address owner,
        address recipient,
        uint256 amount
    ) private {
        bool success = IERC20(token).transferFrom(owner, recipient, amount);
        if (!success) revert TransferFailed();
        emit MockSignatureTransfer(owner, token, recipient, amount);
    }
}
