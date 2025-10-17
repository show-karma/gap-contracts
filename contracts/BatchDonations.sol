// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "solady/src/utils/SafeTransferLib.sol";

interface IPermit2 {
    struct TokenPermissions {
        address token;
        uint256 amount;
    }

    struct PermitTransferFrom {
        TokenPermissions permitted;
        uint256 nonce;
        uint256 deadline;
    }

    struct PermitBatchTransferFrom {
        TokenPermissions[] permitted;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}

contract BatchDonations is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    IPermit2 public constant PERMIT2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    uint256 public constant MAX_PROJECTS_PER_BATCH = 50;

    struct ProjectDonation {
        address project;
        uint256 ethAmount;
        address token;
        uint256 tokenAmount;
    }

    struct DonationStats {
        uint256 totalETH;
        uint256 tokenTransferCount;
    }

    error InvalidProjectAddress();
    error InvalidTokenAmount();
    error IncorrectETHAmount();
    error NoDonationsProvided();
    error TooManyProjects();

    event DonationMade(
        address indexed donor,
        address indexed project,
        address indexed token,
        uint256 amount
    );

    event BatchDonationCompleted(
        address indexed donor,
        uint256 projectCount,
        uint256 totalETH,
        uint256 totalTokenTransfers
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function batchDonate(ProjectDonation[] calldata donations) external payable nonReentrant {
        DonationStats memory stats = _validateAndGetStats(donations);
        _processETHDonations(donations, stats.totalETH);
        _processTokenDonationsTraditional(donations);

        emit BatchDonationCompleted(msg.sender, donations.length, stats.totalETH, stats.tokenTransferCount);
    }

    function batchDonateWithPermit(
        ProjectDonation[] calldata donations,
        IPermit2.PermitBatchTransferFrom memory permit,
        bytes calldata signature
    ) external payable nonReentrant {
        DonationStats memory stats = _validateAndGetStats(donations);
        _processETHDonations(donations, stats.totalETH);

        if (stats.tokenTransferCount > 0) {
            IPermit2.SignatureTransferDetails[] memory transferDetails =
                _buildPermit2TransferDetails(donations, stats.tokenTransferCount);
            PERMIT2.permitTransferFrom(permit, transferDetails, msg.sender, signature);
            _emitTokenDonationEvents(donations);
        }

        emit BatchDonationCompleted(msg.sender, donations.length, stats.totalETH, stats.tokenTransferCount);
    }

    function _validateAndGetStats(ProjectDonation[] calldata donations)
        internal
        pure
        returns (DonationStats memory stats)
    {
        uint256 length = donations.length;
        if (length == 0) revert NoDonationsProvided();
        if (length > MAX_PROJECTS_PER_BATCH) revert TooManyProjects();

        for (uint256 i; i < length; ) {
            ProjectDonation calldata donation = donations[i];

            if (donation.project == address(0)) revert InvalidProjectAddress();

            // Validate token donations and accumulate stats in single pass
            if (donation.token != address(0)) {
                if (donation.tokenAmount == 0) revert InvalidTokenAmount();
                stats.tokenTransferCount++;
            }

            stats.totalETH += donation.ethAmount;

            unchecked { ++i; }
        }
    }

    function _processETHDonations(ProjectDonation[] calldata donations, uint256 totalETH) internal {
        if (msg.value != totalETH) revert IncorrectETHAmount();

        uint256 length = donations.length;
        for (uint256 i; i < length; ) {
            ProjectDonation calldata donation = donations[i];

            if (donation.ethAmount > 0) {
                SafeTransferLib.forceSafeTransferETH(donation.project, donation.ethAmount);
                emit DonationMade(msg.sender, donation.project, address(0), donation.ethAmount);
            }

            unchecked { ++i; }
        }
    }

    function _processTokenDonationsTraditional(ProjectDonation[] calldata donations) internal {
        uint256 length = donations.length;
        for (uint256 i; i < length; ) {
            ProjectDonation calldata donation = donations[i];

            if (donation.token != address(0)) {
                SafeTransferLib.safeTransferFrom(
                    donation.token,
                    msg.sender,
                    donation.project,
                    donation.tokenAmount
                );
                emit DonationMade(
                    msg.sender,
                    donation.project,
                    donation.token,
                    donation.tokenAmount
                );
            }

            unchecked { ++i; }
        }
    }

    function _buildPermit2TransferDetails(
        ProjectDonation[] calldata donations,
        uint256 tokenTransferCount
    ) internal pure returns (IPermit2.SignatureTransferDetails[] memory) {
        IPermit2.SignatureTransferDetails[] memory transferDetails =
            new IPermit2.SignatureTransferDetails[](tokenTransferCount);

        uint256 transferIndex;
        uint256 length = donations.length;

        for (uint256 i; i < length; ) {
            ProjectDonation calldata donation = donations[i];

            if (donation.token != address(0)) {
                transferDetails[transferIndex] = IPermit2.SignatureTransferDetails({
                    to: donation.project,
                    requestedAmount: donation.tokenAmount
                });
                unchecked { ++transferIndex; }
            }

            unchecked { ++i; }
        }

        return transferDetails;
    }

    function _emitTokenDonationEvents(ProjectDonation[] calldata donations) internal {
        uint256 length = donations.length;
        for (uint256 i; i < length; ) {
            ProjectDonation calldata donation = donations[i];

            if (donation.token != address(0)) {
                emit DonationMade(
                    msg.sender,
                    donation.project,
                    donation.token,
                    donation.tokenAmount
                );
            }

            unchecked { ++i; }
        }
    }
}