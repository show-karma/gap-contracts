// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AirdropNFT is ERC721, Ownable {
    using Strings for uint256;

    uint256 public PLATFORM_FEE;
    string public contractURI;
    uint256 private _nextTokenId = 1;

    struct Project {
        string id;
        string baseTokenURI;
        uint256 tokenIdStart;
        uint256 tokenIdEnd;
    }

    mapping(string => Project) public projects;
    mapping(uint256 => string) public tokenToProjectId;

    event NFTsMinted(
        string projectId,
        uint256 tokenIdStart,
        uint256 tokenIdEnd
    );
    event ProjectDeleted(string projectId);
    event ContractURIUpdated(string contractURI);
    event PlatformFeeUpdated(uint256 platformFee);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _platformFee,
        string memory _contractURI
    ) ERC721(_name, _symbol) {
        PLATFORM_FEE = _platformFee;
        contractURI = _contractURI;
    }

    function mintNFTsToContributors(
        string calldata _projectId,
        string calldata _baseTokenURI,
        address[] calldata contributors
    ) external payable {
        require(msg.value >= PLATFORM_FEE, "Insufficient platform fee");
        require(
            bytes(projects[_projectId].id).length == 0,
            "Project already exists"
        );
        require(contributors.length > 0, "No contributors provided");
        require(bytes(_baseTokenURI).length > 0, "Invalid base URI");

        uint256 tokenIdStart = _nextTokenId;
        uint256 tokenIdEnd = tokenIdStart + contributors.length - 1;

        projects[_projectId] = Project({
            id: _projectId,
            baseTokenURI: _baseTokenURI,
            tokenIdStart: tokenIdStart,
            tokenIdEnd: tokenIdEnd
        });

        for (uint256 i = 0; i < contributors.length; i++) {
            uint256 tokenId = tokenIdStart + i;
            _mint(contributors[i], tokenId);
            tokenToProjectId[tokenId] = _projectId;
        }

        _nextTokenId = tokenIdEnd + 1;

        emit NFTsMinted(_projectId, tokenIdStart, tokenIdEnd);
    }

    function deleteProject(string calldata _projectId) external onlyOwner {
        Project storage project = projects[_projectId];
        require(bytes(project.id).length != 0, "Project does not exist");

        // Burn all tokens associated with the project
        for (
            uint256 tokenId = project.tokenIdStart;
            tokenId <= project.tokenIdEnd;
            tokenId++
        ) {
            if (ownerOf(tokenId) != address(0)) {
                _burn(tokenId);
                delete tokenToProjectId[tokenId];
            }
        }

        // Delete the project
        delete projects[_projectId];
        emit ProjectDeleted(_projectId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            ownerOf(tokenId) != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory projectId = tokenToProjectId[tokenId];
        Project storage project = projects[projectId];
        require(bytes(project.id).length > 0, "Project does not exist");

        return project.baseTokenURI;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
        emit ContractURIUpdated(_contractURI);
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        PLATFORM_FEE = _platformFee;
        emit PlatformFeeUpdated(_platformFee);
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner()).transfer(balance);
    }
}
