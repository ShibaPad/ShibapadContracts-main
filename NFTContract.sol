// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";

/*

Shiba-pad Squads

*/
contract ShibaPadSquads is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;

	string private _baseTokenURI = "";
	string private _contractURI = "";

	//this points to the initial IPFS provenance hashes

	uint256 public maxSupply = 3333;
	uint256 public maxPresale = 200;

	mapping(string => bool) private _usedNonces;

	uint256 public pricePerToken = 70000000000000000; //0.07 ETH

	bool public saleLive = false;
	bool public presaleLive = false;
	bool public TokensaleLive = false;
	bool public locked;
    mapping (address => bool) Whitelist;
	uint256 Maxqty = 5;


	constructor() ERC721("ShibaPadSquads", "SPS") {}

	address public token;
	function setToken(address _token) external onlyOwner {
	token = _token;
	}

	//for anti-bot/whale checks
	function publicMint(
		uint256 qty,
		string memory nonce
	) external payable nonReentrant {
		require(TokensaleLive, "BNB payment is not possible");
		require(saleLive, "not live");
		require(qty <= Maxqty, "Exceeded Max mint");
		require(totalSupply() + qty <= maxSupply, "presale out of stock");
		require(pricePerToken * qty == msg.value, "exact amount needed");
		require(!_usedNonces[nonce], "nonce already used");
		_usedNonces[nonce] = true;
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}


	//teh presale
	function presaleMint(
		uint256 qty,
		string memory nonce
	) external payable nonReentrant {
		require(!TokensaleLive, "BNB payment is not possible");
		require(presaleLive, "presale not live");
		require(qty <= Maxqty, "Exceeded Max mint");
		require(totalSupply() + qty <= maxPresale, "presale out of stock");
		require(pricePerToken * qty == msg.value, "exact amount needed");
		require(!_usedNonces[nonce], "nonce already used");
        require(Whitelist[msg.sender]);
		_usedNonces[nonce] = true;
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	function TokenPublicMint(
		uint256 qty,
		string memory nonce
	) external nonReentrant{
		require(TokensaleLive, "Token payment is not possible");
		require(saleLive, "not live");
		require(qty <= Maxqty, "Exceeded Max mint");
		require(totalSupply() + qty <= maxSupply, "presale out of stock");
		require(!_usedNonces[nonce], "nonce already used");

		_usedNonces[nonce] = true;
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}


	//teh presale
	function TokenPresaleMint(
		uint256 qty,
		string memory nonce
	) external nonReentrant {
		require(TokensaleLive, "Token payment is not possible");
		require(presaleLive, "presale not live");
		require(qty <= Maxqty, "Exceeded Max mint");
		require(totalSupply() + qty <= maxPresale, "presale out of stock");
		require(!_usedNonces[nonce], "nonce already used");
        require(Whitelist[msg.sender]);
		_usedNonces[nonce] = true;
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}


	// admin can mint them for giveaways, airdrops etc
	function adminMint(uint256 qty, address to) public onlyOwner {
		require(qty > 0, "minimum 1 token");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(to, totalSupply() + 1);
		}
	}


	//----------------------------------
	//----------- other code -----------
	//----------------------------------
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	function setMaxmint(uint256 _Qty) external onlyOwner {
	Maxqty = _Qty;
	}

	function burn(uint256 tokenId) public virtual {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
		_burn(tokenId);
	}

	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
		return _isApprovedOrOwner(_spender, _tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json"));
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		require(!locked, "locked functions");
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		require(!locked, "locked functions");
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function withdrawSales() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function retrieveERC20(IERC20 erc20Token) public onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function changePresaleStatus() external onlyOwner {
		presaleLive = !presaleLive;
	}

	function changeTokensaleStatus() external onlyOwner {
		TokensaleLive = !TokensaleLive;
	}

	function changeSaleStatus() external onlyOwner {
		saleLive = !saleLive;
	}

	function changePrice(uint256 newPrice) external onlyOwner {
		pricePerToken = newPrice;
	}

	function changeMaxPresale(uint256 _newMaxPresale) external onlyOwner {
		maxPresale = _newMaxPresale;
	}

	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "you can only decrease it");
		maxSupply = newMaxSupply;
	}

	// and for the eternity....
	function lockMetadata() external onlyOwner {
		locked = true;
	}
	

    function whitelistAddress (address[ ]memory users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            Whitelist[users[i]] = true;
    }
    }
    
    function removeWL(address user) public onlyOwner {
        Whitelist[user] = false;
    }


	function setRarity (uint256[]memory _tokenId, uint256 _rarity) external onlyOwner {
	for (uint i = 0; i < _tokenId.length; i++){
		rarity[_tokenId[i]] = _rarity;
	}
	}

	function getrarity(uint256 _tokenId) public view returns (uint256) {
	return rarity[_tokenId];
	}

}