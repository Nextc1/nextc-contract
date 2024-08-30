// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";


// CarbonCredit Token Contract
contract CarbonCredit is  ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    constructor(address initialOwner) ERC20("CarbonCredit", "CC") Ownable(initialOwner) {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}

// OffsetNFT Contract
contract OffsetNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(address initialOwner) ERC721("OffsetNFT", "ONFT") Ownable(initialOwner) {}

    function safeMint(address to, string memory uri) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, uri);
        return newTokenId;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// CarbonOffsetManager Contract
contract CarbonOffsetManager is Ownable {
    CarbonCredit public carbonCredit;
    OffsetNFT public offsetNFT;
    address public centralWallet;

    event ProjectCompleted(uint256 amount, string projectName);
    event OffsetAgainstProject(uint256 amount, address sourceCompany, address sinkCompany, string fromProject, string toProject, uint256 nftId);
    event TokensClaimed(address user, uint256 amount);
    event OffsetToProject(uint256 amount, address sourceCompany, string toProject, uint256 nftId);

    constructor(address _carbonCredit, address _offsetNFT, address _centralWallet) Ownable(msg.sender) {
        carbonCredit = CarbonCredit(_carbonCredit);
        offsetNFT = OffsetNFT(_offsetNFT);
        centralWallet = _centralWallet;
    }

    function projectComplete(uint256 amount, string memory projectName) public onlyOwner {
        carbonCredit.mint(centralWallet, amount);
        emit ProjectCompleted(amount, projectName);
    }

    function offsetAgainstProject(uint256 amount, address sourceCompany, address sinkCompany, string memory fromProject, string memory toProject) public {
        require(carbonCredit.balanceOf(centralWallet) >= amount, "Insufficient tokens in central wallet");
        
        carbonCredit.burn(centralWallet, amount);
        
        string memory nftURI = generateNFTURI(amount, sourceCompany, sinkCompany, fromProject, toProject);
        uint256 nftId = offsetNFT.safeMint(sinkCompany, nftURI);
        
        emit OffsetAgainstProject(amount, sourceCompany, sinkCompany, fromProject, toProject, nftId);
    }

    function claim(address user, uint256 amount) public onlyOwner {
        require(carbonCredit.balanceOf(centralWallet) >= amount, "Insufficient tokens in central wallet");
        carbonCredit.transferFrom(centralWallet, user, amount);
        emit TokensClaimed(user, amount);
    }

    function offsetToProject(uint256 amount, address sourceCompany, string memory toProject) public {
        require(carbonCredit.balanceOf(sourceCompany) >= amount, "Insufficient tokens in source company wallet");
        
        // Transfer tokens from the source company to this contract
        carbonCredit.transferFrom(sourceCompany, address(this), amount);
        
        // Burn the tokens
        carbonCredit.burn(address(this), amount);
        
        string memory nftURI = generateNFTURI(amount, sourceCompany, address(0), "", toProject);
        uint256 nftId = offsetNFT.safeMint(sourceCompany, nftURI);
        
        emit OffsetToProject(amount, sourceCompany, toProject, nftId);
    }

    function generateNFTURI(uint256 amount, address sourceCompany, address sinkCompany, string memory fromProject, string memory toProject) internal pure returns (string memory) {
        // In a real-world scenario, you would generate a proper JSON metadata here
        // For simplicity, we're just concatenating the data
        return string(abi.encodePacked(
            "Amount:", Strings.toString(amount),
            ",Source:", Strings.toHexString(uint160(sourceCompany), 20),
            ",Sink:", Strings.toHexString(uint160(sinkCompany), 20),
            ",From:", fromProject,
            ",To:", toProject
        ));
    }

    function setCentralWallet(address newCentralWallet) public onlyOwner {
        centralWallet = newCentralWallet;
    }
}