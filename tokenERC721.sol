//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";

contract TOKEN721 is ERC165,IERC721 {
    address public owner;
    mapping(uint256 => address) private _owners;//address owner for an NFT
    mapping(address => uint256) private _balances;//NFT's owned by an address
    mapping(uint256 => address) private _tokenApprovals;//address with permission to manage an NFT
    mapping(address => mapping(address => bool)) private _operatorApprovals;//operators with permission to manage all NFT's of a given address

    
    constructor(){
        owner=msg.sender;
    }
    
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }

    //override function from ERC165 to check if this interface is supported
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165,IERC165) returns(bool){
        return interfaceId==type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    //GETTER functions
    function balanceOf(address _owner) public view virtual override returns(uint256){
        require(_owner!=address(0),"ERC721 ERROR: zero address");
        return _balances[_owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns(address){
        address _owner= _owners[tokenId];
        require(_owner!=address(0),"ERC721 ERROR: toekn id does not exist");
        return _owner;
    }
    
    //APPROVAL functions
    function approve(address to,uint256 tokenId) public virtual override {
        address _owner=ownerOf(tokenId);
        require(to!=_owner,"ERC721 ERROR: destination address must be different");
        require(msg.sender==_owner||_operatorApprovals[_owner][msg.sender],"ERC721 EROR:you are not the owner or you don't have permissions");
        _tokenApprovals[tokenId]=to;
        emit Approval(ownerOf(tokenId),to,tokenId);
    }
    function setApprovalForAll(address operator, bool approved) public virtual override{
        require(operator!=msg.sender, "ERC721 ERROR: operator address must be different");
        _operatorApprovals[msg.sender][operator]=approved;
        emit ApprovalForAll(msg.sender,operator,approved);
    }
    function getApproved(uint256 tokenId) public view virtual override returns(address) {
        require(_owners[tokenId]!=address(0), "ERC721 ERROR: token id does not exist");
        return _tokenApprovals[tokenId];
    }
    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool){
        return _operatorApprovals[_owner][_operator];
    }

    //TRANSFER functions
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from,to,tokenId,"");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override{
        require(msg.sender==from || _operatorApprovals[from][msg.sender],"ERC721 EROR:you are not the owner or you don't have permissions");
        _safeTransfer(from,to,tokenId,_data);
    }
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual{
        _transfer(from,to,tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data),"ERC721 ERROR: non ERC721 compatible receiver");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override{
        require(msg.sender==from||_tokenApprovals[tokenId]==msg.sender,"ERC721 EROR:you are not the owner or you don't have permissions");
        _transfer(from,to,tokenId);
    }
    function _transfer(address from, address to, uint256 tokenId) internal virtual{
        require(ownerOf(tokenId) == from, "ERC721 ERROR: token id does not exist");
        require(to!=address(0), "ERC721 ERROR: destination address cannot be zero");
        _tokenApprovals[tokenId]=address(0);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from,to,tokenId);
    }
    

    //MINT functions
    //firstly checks if the destination address can receive ERC721 tokens
    function _safeMint(address to, uint256 tokenId) public{
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to, uint256 tokenId, bytes memory _data) public {
        _mint(to,tokenId);
        //if the destination address is a contract we must check if it's ERC721 compatible
        require(_checkOnERC721Received(address(0),to, tokenId,_data), "ERC721 ERROR: transfer to non ERC721 implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual onlyOwner {
        require(to!= address(0), "ERC721 ERROR: mint to zero");
        require(_owners[tokenId]==address(0), "ERC721 EROR: token already minted");
        //_beforeTokenTransfer(address(0),to,tokenId);//things to do (if necessary) before minting the nft
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) 
        private returns (bool)
    {
        if (isContract(to)){
            try ERC721Receiver(to).onERC721Received(msg.sender,from,tokenId,_data) returns (bytes4 retval)
              { 
                  return retval == ERC721Receiver(to).onERC721Received.selector;
              }
            catch (bytes memory reason){
              if (reason.length==0){
                  revert("ERC721:transfer to non ERC721 implementer");
              }  
              else { 
                     assembly {revert(add(32,reason),mload(reason))}
               }
            }
        }
        else { return true;
        }
    }

    function isContract(address _addr) private view returns(bool){
        uint32 size;
        assembly{size:=extcodesize(_addr)}
        return (size >0);
    }
    
 
}