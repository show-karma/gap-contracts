// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GitcoinAirdrop is ERC721, Ownable {
    using Strings for uint256;

    uint256 public PLATFORM_FEE;
    uint256 private _nextTokenId = 1;

    struct Project {
        string id;
        string baseTokenURI;
        uint256 tokenIdStart;
        uint256 tokenIdEnd;
    }

    mapping(string => Project) public projects;
    mapping(uint256 => string) public tokenToProjectId;
    mapping(uint256 => address) public tokenToOwner;

    event NFTsMinted(
        string projectId,
        uint256 tokenIdStart,
        uint256 tokenIdEnd
    );
    event ProjectDeleted(string projectId);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _platformFee
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        PLATFORM_FEE = _platformFee;
    }

    function mintProjectNFTs(
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
            tokenToOwner[tokenId] = contributors[i];
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
            address owner = tokenToOwner[tokenId];
            if (owner != address(0)) {
                _burn(tokenId);
                delete tokenToOwner[tokenId];
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

        return
            string(abi.encodePacked(project.baseTokenURI, tokenId.toString()));
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner()).transfer(balance);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721) returns (address) {
        tokenToOwner[tokenId] = to;
        return super._update(to, tokenId, auth);
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = tokenToOwner[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }
}
