pragma solidity ^0.5.6;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}

library Counters {
  using SafeMath for uint256;

  struct Counter {
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    counter._value += 1;
  }

  function decrement(Counter storage counter) internal {
    counter._value = counter._value.sub(1);
  }
}

interface IKIP13 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IKIP17 is IKIP13 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function balanceOf(address owner) public view returns (uint256 balance);

  function ownerOf(uint256 tokenId) public view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public;

  function approve(address to, uint256 tokenId) public;

  function getApproved(uint256 tokenId) public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;

  function isApprovedForAll(address owner, address operator) public view returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public;
}

contract KIP13 is IKIP13 {
  /*
   * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
   */
  bytes4 private constant _INTERFACE_ID_KIP13 = 0x01ffc9a7;

  mapping(bytes4 => bool) private _supportedInterfaces;

  constructor() internal {
    _registerInterface(_INTERFACE_ID_KIP13);
  }

  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId) internal {
    require(interfaceId != 0xffffffff, 'KIP13: invalid interface id');
    _supportedInterfaces[interfaceId] = true;
  }
}

contract KIP17 is KIP13, IKIP17 {
  using SafeMath for uint256;
  using Address for address;
  using Counters for Counters.Counter;

  // Equals to `bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"))`
  bytes4 private constant _KIP17_RECEIVED = 0x6745782b;
  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  mapping(uint256 => address) private _tokenOwner;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => Counters.Counter) private _ownedTokensCount;
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  /*
   *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
   *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
   *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
   *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
   *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
   *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
   *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
   *
   *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
   *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
   */
  bytes4 private constant _INTERFACE_ID_KIP17 = 0x80ac58cd;

  constructor() public {
    _registerInterface(_INTERFACE_ID_KIP17);
  }

  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), 'KIP17: balance query for the zero address');

    return _ownedTokensCount[owner].current();
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0), 'KIP17: owner query for nonexistent token');

    return owner;
  }

  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner, 'KIP17: approval to current owner');

    require(
      msg.sender == owner || isApprovedForAll(owner, msg.sender),
      'KIP17: approve caller is not owner nor approved for all'
    );

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), 'KIP17: approved query for nonexistent token');

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender, 'KIP17: approve to caller');

    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    require(_isApprovedOrOwner(msg.sender, tokenId), 'KIP17: transfer caller is not owner nor approved');
    _transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public {
    transferFrom(from, to, tokenId);
    require(_checkOnKIP17Received(from, to, tokenId, _data), 'KIP17: transfer to non KIP17Receiver implementer');
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId), 'KIP17: operator query for nonexistent token');
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0), 'KIP17: mint to the zero address');
    require(!_exists(tokenId), 'KIP17: token already minted');

    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to].increment();

    emit Transfer(address(0), to, tokenId);
  }

  function _burn(address owner, uint256 tokenId) internal {
    require(ownerOf(tokenId) == owner, 'KIP17: burn of token that is not own');

    _clearApproval(tokenId);

    _ownedTokensCount[owner].decrement();
    _tokenOwner[tokenId] = address(0);

    emit Transfer(owner, address(0), tokenId);
  }

  function _burn(uint256 tokenId) internal {
    _burn(ownerOf(tokenId), tokenId);
  }

  function _transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(ownerOf(tokenId) == from, 'KIP17: transfer of token that is not own');
    require(to != address(0), 'KIP17: transfer to the zero address');

    _clearApproval(tokenId);

    _ownedTokensCount[from].decrement();
    _ownedTokensCount[to].increment();

    _tokenOwner[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _checkOnKIP17Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal returns (bool) {
    bool success;
    bytes memory returndata;

    if (!to.isContract()) {
      return true;
    }

    (success, returndata) = to.call(abi.encodeWithSelector(_ERC721_RECEIVED, msg.sender, from, tokenId, _data));
    if (returndata.length != 0 && abi.decode(returndata, (bytes4)) == _ERC721_RECEIVED) {
      return true;
    }

    (success, returndata) = to.call(abi.encodeWithSelector(_KIP17_RECEIVED, msg.sender, from, tokenId, _data));
    if (returndata.length != 0 && abi.decode(returndata, (bytes4)) == _KIP17_RECEIVED) {
      return true;
    }

    return false;
  }

  function _clearApproval(uint256 tokenId) private {
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

contract IKIP17Enumerable is IKIP17 {
  function totalSupply() public view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

contract KIP17Enumerable is KIP13, KIP17, IKIP17Enumerable {
  mapping(address => uint256[]) private _ownedTokens;
  mapping(uint256 => uint256) private _ownedTokensIndex;
  mapping(uint256 => uint256) private _allTokensIndex;

  uint256[] private _allTokens;
  /*
   *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
   *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
   *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
   *
   *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
   */
  bytes4 private constant _INTERFACE_ID_KIP17_ENUMERABLE = 0x780e9d63;

  constructor() public {
    // register the supported interface to conform to KIP17Enumerable via KIP13
    _registerInterface(_INTERFACE_ID_KIP17_ENUMERABLE);
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    require(index < balanceOf(owner), 'KIP17Enumerable: owner index out of bounds');
    return _ownedTokens[owner][index];
  }

  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply(), 'KIP17Enumerable: global index out of bounds');
    return _allTokens[index];
  }

  function _transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    super._transferFrom(from, to, tokenId);

    _removeTokenFromOwnerEnumeration(from, tokenId);

    _addTokenToOwnerEnumeration(to, tokenId);
  }

  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _addTokenToOwnerEnumeration(to, tokenId);

    _addTokenToAllTokensEnumeration(tokenId);
  }

  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    _removeTokenFromOwnerEnumeration(owner, tokenId);
    _ownedTokensIndex[tokenId] = 0;

    _removeTokenFromAllTokensEnumeration(tokenId);
  }

  function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
    return _ownedTokens[owner];
  }

  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
  }

  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId;
      _ownedTokensIndex[lastTokenId] = tokenIndex;
    }

    _ownedTokens[from].length--;
  }

  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId;
    _allTokensIndex[lastTokenId] = tokenIndex;

    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
  }
}

contract IKIP17Metadata is IKIP17 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract KIP17Metadata is KIP13, KIP17, IKIP17Metadata {
  string private _name;
  string private _symbol;
  mapping(uint256 => string) private _tokenURIs;

  /*
   *     bytes4(keccak256('name()')) == 0x06fdde03
   *     bytes4(keccak256('symbol()')) == 0x95d89b41
   *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
   *
   *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
   */
  bytes4 private constant _INTERFACE_ID_KIP17_METADATA = 0x5b5e139f;

  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;

    _registerInterface(_INTERFACE_ID_KIP17_METADATA);
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId), 'KIP17Metadata: URI query for nonexistent token');
    return _tokenURIs[tokenId];
  }

  function _setTokenURI(uint256 tokenId, string memory uri) internal {
    require(_exists(tokenId), 'KIP17Metadata: URI set of nonexistent token');
    _tokenURIs[tokenId] = uri;
  }

  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}

contract KIP17Full is KIP17, KIP17Enumerable, KIP17Metadata {
  constructor(string memory name, string memory symbol) public KIP17Metadata(name, symbol) {}
}

contract KIP17Burnable is KIP13, KIP17 {
  /*
   *     bytes4(keccak256('burn(uint256)')) == 0x42966c68
   *
   *     => 0x42966c68 == 0x42966c68
   */
  bytes4 private constant _INTERFACE_ID_KIP17_BURNABLE = 0x42966c68;

  /**
   * @dev Constructor function.
   */
  constructor() public {
    // register the supported interface to conform to KIP17Burnable via KIP13
    _registerInterface(_INTERFACE_ID_KIP17_BURNABLE);
  }

  /**
   * @dev Burns a specific KIP17 token.
   * @param tokenId uint256 id of the KIP17 token to be burned.
   */
  function burn(uint256 tokenId) public {
    require(_isApprovedOrOwner(msg.sender, tokenId), 'KIP17Burnable: caller is not owner nor approved');
    _burn(tokenId);
  }
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private _pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender), 'PauserRole: caller does not have the Pauser role');
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return _pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    _pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    _pausers.remove(account);
    emit PauserRemoved(account);
  }
}

contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

  function paused() public view returns (bool) {
    return _paused;
  }

  modifier whenNotPaused() {
    require(!_paused, 'Pausable: paused');
    _;
  }

  modifier whenPaused() {
    require(_paused, 'Pausable: not paused');
    _;
  }

  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

contract KIP17Pausable is KIP13, KIP17, Pausable {
  /*
   *     bytes4(keccak256('paused()')) == 0x5c975abb
   *     bytes4(keccak256('pause()')) == 0x8456cb59
   *     bytes4(keccak256('unpause()')) == 0x3f4ba83a
   *     bytes4(keccak256('isPauser(address)')) == 0x46fbf68e
   *     bytes4(keccak256('addPauser(address)')) == 0x82dc1ec4
   *     bytes4(keccak256('renouncePauser()')) == 0x6ef8d66d
   *
   *     => 0x5c975abb ^ 0x8456cb59 ^ 0x3f4ba83a ^ 0x46fbf68e ^ 0x82dc1ec4 ^ 0x6ef8d66d == 0x4d5507ff
   */
  bytes4 private constant _INTERFACE_ID_KIP17_PAUSABLE = 0x4d5507ff;

  constructor() public {
    _registerInterface(_INTERFACE_ID_KIP17_PAUSABLE);
  }

  function approve(address to, uint256 tokenId) public whenNotPaused {
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address to, bool approved) public whenNotPaused {
    super.setApprovalForAll(to, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public whenNotPaused {
    super.transferFrom(from, to, tokenId);
  }
}

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private _minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender), 'MinterRole: caller does not have the Minter role');
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return _minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    _minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    _minters.remove(account);
    emit MinterRemoved(account);
  }
}

contract KIP17Mintable is KIP17, MinterRole {
  /*
   *     bytes4(keccak256('isMinter(address)')) == 0xaa271e1a
   *     bytes4(keccak256('addMinter(address)')) == 0x983b2d56
   *     bytes4(keccak256('renounceMinter()')) == 0x98650275
   *     bytes4(keccak256('mint(address,uint256)')) == 0x40c10f19
   *
   *     => 0xaa271e1a ^ 0x983b2d56 ^ 0x98650275 ^ 0x40c10f19 == 0xeab83e20
   */
  bytes4 private constant _INTERFACE_ID_KIP17_MINTABLE = 0xeab83e20;

  constructor() public {
    _registerInterface(_INTERFACE_ID_KIP17_MINTABLE);
  }

  function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
    _mint(to, tokenId);
    return true;
  }
}

contract KIP17MetadataMintable is KIP13, KIP17, KIP17Metadata, MinterRole {
  /*
   *     bytes4(keccak256('mintWithTokenURI(address,uint256,string)')) == 0x50bb4e7f
   *     bytes4(keccak256('isMinter(address)')) == 0xaa271e1a
   *     bytes4(keccak256('addMinter(address)')) == 0x983b2d56
   *     bytes4(keccak256('renounceMinter()')) == 0x98650275
   *
   *     => 0x50bb4e7f ^ 0xaa271e1a ^ 0x983b2d56 ^ 0x98650275 == 0xfac27f46
   */
  bytes4 private constant _INTERFACE_ID_KIP17_METADATA_MINTABLE = 0xfac27f46;

  constructor() public {
    _registerInterface(_INTERFACE_ID_KIP17_METADATA_MINTABLE);
  }

  function mintWithTokenURI(
    address to,
    uint256 tokenId,
    string memory tokenURI
  ) public onlyMinter returns (bool) {
    _mint(to, tokenId);
    _setTokenURI(tokenId, tokenURI);
    return true;
  }
}

contract KIP17Token is KIP17Full, KIP17Mintable, KIP17MetadataMintable, KIP17Burnable, KIP17Pausable {
  constructor(string memory name, string memory symbol) public KIP17Full(name, symbol) {}
}

contract Ownable {
  address private _owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    _setOwner(msg.sender);
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, 'Ownable: caller is not the owner');
    _;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

contract CrazyCatAdventure is KIP17Token('Crazy Cat Adventure', 'CCA'), Ownable {
  function setTokenURI(uint256 tokenId, string memory uri) public onlyMinter {
    _setTokenURI(tokenId, uri);
  }
}
